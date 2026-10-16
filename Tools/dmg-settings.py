# dmgbuild settings for dist/PawsOff-mac.dmg (used by Tools/make-dmg.sh).
# The window is 660 wide; its height comes from Tools/make-dmg.sh: the picture (596 with the
# first-launch guide, 400 for the notarized version) plus the title bar. Icon centres match the arrow drawn by Tools/make-installer-art.swift.
import os.path

app = defines.get("app", "Paws Off.app")  # noqa: F821 (provided by dmgbuild)
app_name = os.path.basename(app)

format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {"Applications": "/Applications"}
hide_extensions = [app_name]

icon = defines.get("volume_icon")  # noqa: F821
background = defines.get("background")  # noqa: F821

window_rect = ((160, 120), (660, int(defines.get("height", "628"))))  # noqa: F821
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False

icon_size = 112
text_size = 13
arrange_by = None
icon_locations = {
    app_name: (170, 200),
    "Applications": (490, 200),
}
