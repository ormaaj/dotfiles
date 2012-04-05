import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.UpdatePointer
import XMonad.Config.Kde
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Hooks.FadeInactive
import XMonad.Util.Run
import XMonad.Util.WindowProperties (getProp32s)
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.XMonad
import XMonad.Prompt.Window
import XMonad.Layout.NoBorders
import XMonad.Layout.LayoutHints
import XMonad.Layout.ResizableTile
import XMonad.Layout.MouseResizableTile
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import qualified XMonad.Actions.FlexibleManipulate as Flex
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import Graphics.X11.Xlib
import System.IO

main = do
    xmproc <- spawnPipe "xmobar"
    xmonad kde4Config
        { manageHook         = myManageHook <+> manageHook kde4Config
        , logHook            = myLogHook xmproc
        , layoutHook         = myLayout
        , startupHook        = startupHook kde4Config >> setWMName "LG3D"
        --, startupHook        = setWMName "LG3D"
        , focusFollowsMouse  = True
        , borderWidth        = 2
        , focusedBorderColor = "#0066ff"
        , normalBorderColor  = "#dddddd"
        , terminal           = "konsole"
        -- , modMask            = mod4Mask -- switch modmask to super
        , keys               = myKeys <+> keys kde4Config
        , mouseBindings      = myMouse <+> mouseBindings kde4Config
        }
        where
            myLayout         = avoidStruts $ smartBorders $ mkToggle (single FULL) (mouseResizableTile { draggerType = BordersDragger } ||| mouseResizableTile { isMirrored = True, draggerType = BordersDragger })
            floatByClassName = ["MPlayer", "Gimp", "Kmix", "frost-Frost", "sun-awt-X11-XFramePeer", "Dialog", "Plasma", "Plasma-desktop", "Qt-subapplication", "Korgac", "Test_shell", "Conky"] --, "Qjackctl"]
            floatByTitle     = ["alsamixer"]

            myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
                [ ((modm, xK_a), sendMessage ShrinkSlave)
                , ((modm, xK_z), sendMessage ExpandSlave)
                , ((modm, xK_F12), xmonadPrompt defaultXPConfig)
                , ((modm, xK_p), shellPrompt defaultXPConfig) 
                , ((modm .|. shiftMask, xK_g), windowPromptGoto defaultXPConfig)
                , ((modm .|. shiftMask, xK_b), windowPromptBring defaultXPConfig)
                , ((modm, xK_b), sendMessage ToggleStruts) --toggles dock gaps
                , ((modm, xK_x), sendMessage $ Toggle FULL)
                , ((modm .|. controlMask, xK_k), nextWS)
                , ((modm .|. controlMask, xK_j), prevWS)
--                  , ((modm, xK_p), spawn "exe=`dmenu_path | dmenu` && eval \"exec $exe\"") -- %! Launch dmenu
                ]

            myMouse conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
                [ ((modm, button3), (\w -> focus w >> Flex.mouseWindow Flex.discrete w)) ]

            myLogHook h      = dynamicLogWithPP $ xmobarPP
                { ppOutput   = hPutStrLn h
                , ppTitle    = xmobarColor "green" "" . shorten 85
--                    , ppLayout   = (>> "")
                }

            myManageHook     = composeAll . concat $
                [ [manageDocks]
                , [className =? c --> doFloat | c <- floatByClassName]
                , [title     =? t --> doFloat | t <- floatByTitle]
                , [isFullscreen --> doFullFloat]
                -- Allows focusing other monitors without killing the fullscreen
                --  [ isFullscreen --> (doF W.focusDown <+> doFullFloat)
                ]

-- vim: set ft=haskell noai nowrap et :
