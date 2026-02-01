import os
import datetime
import asyncio
from ignis.menu_model import IgnisMenuModel, IgnisMenuItem, IgnisMenuSeparator
from ignis import widgets
from ignis import utils
from ignis.css_manager import CssManager, CssInfoPath
from ignis.services.audio import AudioService
from ignis.services.system_tray import SystemTrayService, SystemTrayItem
from ignis.services.hyprland import HyprlandService, HyprlandWorkspace
from ignis.services.niri import NiriService, NiriWorkspace
from ignis.services.notifications import NotificationService
from ignis.services.mpris import MprisService, MprisPlayer
from ignis.services.upower import UPowerService

css_manager = CssManager.get_default()
css_manager.widgets_style_priority = "user"
css_manager.apply_css(
    CssInfoPath(
        name="main",
        compiler_function=lambda path: utils.sass_compile(path=path),
        priority="user",
        path=os.path.join(utils.get_current_dir(), "style.scss"),
    )
)
print("Widget style priority:", css_manager._widgets_style_priority)

from modules import Launcher, NotificationPopup , ControlCenter
# from user_options import user_options

audio = AudioService.get_default()
system_tray = SystemTrayService.get_default()
hyprland = HyprlandService.get_default()
niri = NiriService.get_default()
notifications = NotificationService.get_default()
mpris = MprisService.get_default()
upower = UPowerService.get_default()


def hyprland_workspace_button(workspace: HyprlandWorkspace) -> widgets.Button:
    widget = widgets.Button(
        css_classes=["workspace"],
        on_click=lambda x: workspace.switch_to(),
        child=widgets.Label(label=str(workspace.id)),
    )
    if workspace.id == hyprland.active_workspace.id:
        widget.add_css_class("active")

    return widget


def niri_workspace_button(workspace: NiriWorkspace) -> widgets.Button:
    widget = widgets.Button(
        css_classes=["workspace"],
        on_click=lambda x: workspace.switch_to(),
        # child=widgets.Label(label=str(workspace.idx)),
    )
    if workspace.is_active:
        widget.add_css_class("active")

    return widget


def workspace_button(workspace) -> widgets.Button:
    if hyprland.is_available:
        return hyprland_workspace_button(workspace)
    elif niri.is_available:
        return niri_workspace_button(workspace)
    else:
        return widgets.Button()


def hyprland_scroll_workspaces(direction: str) -> None:
    current = hyprland.active_workspace["id"]
    if direction == "up":
        target = current - 1
        hyprland.switch_to_workspace(target)
    else:
        target = current + 1
        if target == 11:
            return
        hyprland.switch_to_workspace(target)


def niri_scroll_workspaces(monitor_name: str, direction: str) -> None:
    current = list(
        filter(lambda w: w.is_active and w.output ==
               monitor_name, niri.workspaces)
    )[0].idx
    if direction == "up":
        target = current + 1
        niri.switch_to_workspace(target)
    else:
        target = current - 1
        niri.switch_to_workspace(target)


def scroll_workspaces(direction: str, monitor_name: str = "") -> None:
    if hyprland.is_available:
        hyprland_scroll_workspaces(direction)
    elif niri.is_available:
        niri_scroll_workspaces(monitor_name, direction)
    else:
        pass


def hyprland_workspaces() -> widgets.EventBox:
    return widgets.EventBox(
        on_scroll_up=lambda x: scroll_workspaces("up"),
        on_scroll_down=lambda x: scroll_workspaces("down"),
        css_classes=["workspaces"],
        spacing=5,
        child=hyprland.bind_many(  # bind also to active_workspace to regenerate workspaces list when active workspace changes
            ["workspaces", "active_workspace"],
            transform=lambda workspaces, active_workspace: [
                workspace_button(i) for i in workspaces
            ],
        ),
    )


def niri_workspaces(monitor_name: str) -> widgets.EventBox:
    return widgets.EventBox(
        vertical=True,
        on_scroll_up=lambda x: scroll_workspaces("up", monitor_name),
        on_scroll_down=lambda x: scroll_workspaces("down", monitor_name),
        css_classes=["workspaces"],
        spacing=4,
        child=niri.bind(
            "workspaces",
            transform=lambda value: [
                workspace_button(i) for i in value if i.output == monitor_name
            ],
        ),
    )


def workspaces(monitor_name: str) -> widgets.EventBox:
    if hyprland.is_available:
        return hyprland_workspaces()
    elif niri.is_available:
        return niri_workspaces(monitor_name)
    else:
        return widgets.EventBox()


def mpris_title(player: MprisPlayer) -> widgets.Box:
    return widgets.Box(
        spacing=10,
        css_classes=["mpris-title"],
        setup=lambda self: player.connect(
            "closed",
            lambda x: self.unparent(),  # remove widget when player is closed
        ),
        child=[
            widgets.Icon(image="audio-x-generic-symbolic"),
            widgets.Label(
                ellipsize="end",
                max_width_chars=20,
                label=player.bind("title"),
            ),
        ],
    )


def media() -> widgets.Box:
    return widgets.Box(
        spacing=10,
        css_classes=["media"],
        child=[
            widgets.Label(
                label="No media players",
                visible=mpris.bind("players", lambda value: len(value) == 0),
            )
        ],
        setup=lambda self: mpris.connect(
            "player-added", lambda x, player: self.append(mpris_title(player))
        ),
    )


def hyprland_client_title() -> widgets.Label:
    return widgets.Label(
        ellipsize="end",
        max_width_chars=40,
        label=hyprland.active_window.bind("title"),
    )


def niri_client_title(monitor_name) -> widgets.Label:
    return widgets.Label(
        ellipsize="end",
        max_width_chars=40,
        visible=niri.bind(
            "active_output", lambda output: output == monitor_name),
        label=niri.active_window.bind("title"),
    )


def client_title(monitor_name: str) -> widgets.Label:
    if hyprland.is_available:
        return hyprland_client_title()
    elif niri.is_available:
        return niri_client_title(monitor_name)
    else:
        return widgets.Label()


def current_notification() -> widgets.Label:
    return widgets.Label(
        ellipsize="end",
        max_width_chars=20,
        label=notifications.bind(
            "notifications", lambda value: value[-1].summary if len(
                value) > 0 else None
        ),
    )


def clock_h() -> widgets.Label:
    # poll for current time every second
    return widgets.Label(
        css_classes=["clock"],
        label=utils.Poll(
            1_000, lambda self: datetime.datetime.now().strftime("%H")
        ).bind("output"),
    )

def clock_m() -> widgets.Label:
    # poll for current time every second
    return widgets.Label(
        css_classes=["clock"],
        label=utils.Poll(
            1_000, lambda self: datetime.datetime.now().strftime("%M")
        ).bind("output"),
    )


def speaker_volume() -> widgets.Box:
    return widgets.Box(
        css_classes=["speaker-volume"],
        child=[
            widgets.Icon(
                image=audio.speaker.bind("icon_name")
            ),
            widgets.Label(
                label=audio.speaker.bind(
                    "volume", transform=lambda value: str(value))
            ),
        ]
    )

def battery_percentage() -> widgets.Box:
    return widgets.Box(
        css_classes=["battery-percentage"],
        child=[
            widgets.Icon(
                image=upower.display_device.bind("icon_name")
            ),
            widgets.Label(
                label=upower.display_device.bind(
                    "percent", transform=lambda value: str(value) + "%")
            ),
        ]
    )


def hyprland_keyboard_layout() -> widgets.EventBox:
    return widgets.EventBox(
        on_click=lambda self: hyprland.main_keyboard.switch_layout("next"),
        child=[widgets.Label(
            label=hyprland.main_keyboard.bind("active_keymap"))],
    )


def niri_keyboard_layout() -> widgets.EventBox:
    return widgets.EventBox(
        on_click=lambda self: niri.switch_kb_layout(),
        child=[widgets.Label(
            label=niri.keyboard_layouts.bind("current_name"))],
    )


def keyboard_layout() -> widgets.EventBox:
    if hyprland.is_available:
        return hyprland_keyboard_layout()
    elif niri.is_available:
        return niri_keyboard_layout()
    else:
        return widgets.EventBox()


def tray_item(item: SystemTrayItem) -> widgets.Button:
    if item.menu:
        menu = item.menu.copy()
    else:
        menu = None

    return widgets.Button(
        child=widgets.Box(
            vertical=True,
            child=[
                widgets.Icon(image=item.bind("icon"), pixel_size=18),
                menu,
            ]
        ),
        setup=lambda self: item.connect("removed", lambda x: self.unparent()),
        tooltip_text=item.bind("tooltip"),
        on_click=lambda x: menu.popup() if menu else None,
        on_right_click=lambda x: menu.popup() if menu else None,
        css_classes=["tray-item"],
    )


def tray():
    return widgets.Box(
        vertical=True,
        setup=lambda self: system_tray.connect(
            "added", lambda x, item: self.append(tray_item(item))
        ),
        spacing=8,
    )

def menu() -> widgets.Button:
    return widgets.Button(
        css_classes=["menu"],
        on_click=lambda x: create_exec_task("ignis toggle-window ignis_LAUNCHER"),
        child=widgets.Icon(image="/home/ewan/.config/ignis/nixos.svg", pixel_size=24),
    )


def speaker_slider() -> widgets.Scale:
    return widgets.Scale(
        min=0,
        max=100,
        step=1,
        value=audio.speaker.bind("volume"),
        on_change=lambda x: audio.speaker.set_volume(x.value),
        css_classes=["volume-slider"],  # we will customize style in style.css
    )


def create_exec_task(cmd: str) -> None:
    # use create_task to run async function in a regular (sync) one
    asyncio.create_task(utils.exec_sh_async(cmd))


def logout() -> None:
    if hyprland.is_available:
        create_exec_task("hyprctl dispatch exit 0")
    elif niri.is_available:
        create_exec_task("niri msg action quit")
    else:
        pass


def power_menu() -> widgets.Button:
    menu = widgets.PopoverMenu(
        model=IgnisMenuModel(
            IgnisMenuItem(
                label="Lock",
                on_activate=lambda x: create_exec_task("hyprlock"),
            ),
            IgnisMenuSeparator(),
            IgnisMenuItem(
                label="Suspend",
                on_activate=lambda x: create_exec_task("systemctl suspend"),
            ),
            IgnisMenuItem(
                label="Hibernate",
                on_activate=lambda x: create_exec_task("systemctl hibernate"),
            ),
            IgnisMenuSeparator(),
            IgnisMenuItem(
                label="Reboot",
                on_activate=lambda x: create_exec_task("systemctl reboot"),
            ),
            IgnisMenuItem(
                label="Shutdown",
                on_activate=lambda x: create_exec_task("systemctl poweroff"),
            ),
            IgnisMenuSeparator(),
            IgnisMenuItem(
                label="Logout",
                enabled=hyprland.is_available or niri.is_available,
                on_activate=lambda x: logout(),
            ),
        ),
    )
    return widgets.Button(
        child=widgets.Box(
            vertical=True,
            child=[widgets.Icon(
                image="system-shutdown-symbolic", pixel_size=24), menu]
        ),
        css_classes=["power"],
        on_click=lambda x: menu.popup(),
    )

def top() -> widgets.Box:
    return widgets.Box(
        vertical=True,
        child=[
            menu(),
            widgets.Separator(vertical=True, css_classes=["middle-separator"]),
            tray()
        ],
        css_classes=["top"]
    )

def center(monitor_name: str) -> widgets.Box:
    return widgets.Box(
        vertical=True,
        child=[workspaces(monitor_name)],
    )

def bottom() -> widgets.Box:
    return widgets.Box(
        vertical=True,
        child=[
            clock_h(),
            clock_m(),
            widgets.Separator(vertical=True, css_classes=["middle-separator"]),
            power_menu()
        ],
        css_classes=["bottom"]
    )

# def center() -> widgets.Box:
#     return widgets.Box(
#         vertical=True,
#         css_classes=["center-section"],
#         child=[
#             current_notification(),
#             widgets.Separator(vertical=False, css_classes=["middle-separator"]),
#             media(),
#         ],
#         spacing=10,
#     )


def right() -> widgets.Box:
    return widgets.Box(
        vertical=True,
        css_classes=["right-section"],
        child=[
            tray(),
            keyboard_layout(),
            speaker_volume(),
            speaker_slider(),
            battery_percentage(),
            power_menu(),
        ],
        spacing=10,
    )


def bar(monitor_id: int = 0) -> widgets.Window:
    monitor_name = utils.get_monitor(
        monitor_id).get_connector()  # type: ignore
    return widgets.Window(
        namespace=f"ignis_bar_{monitor_id}",
        monitor=monitor_id,
        anchor=["top", "left", "bottom"],
        exclusivity="exclusive",
        child=widgets.CenterBox(
            vertical=True,
            css_classes=["bar"],
            start_widget=top(),
            center_widget=center(monitor_name),  # type: ignore
            end_widget=bottom(),
        ),
    )



# this will display bar on all monitors
for i in range(utils.get_n_monitors()):
    bar(i)
    NotificationPopup(i)

Launcher()
ControlCenter()
