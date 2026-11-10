if [ -d "/sys/class/drm" ]; then

    DRV_NAME=""

    if [ -e "/sys/class/drm/card0/device/driver" ]; then
        DRV_NAME=$(basename "$(readlink -f /sys/class/drm/card0/device/driver)" 2>/dev/null)
    fi

    # Trigger software overrides on universal fallback / legacy drivers lacking proper 3D acceleration
    case "$DRV_NAME" in
        simpledrm|simple-framebuffer|vkms|bochnet|bochs-drm)
        
            # Wlroots / Compositor Level
            #export WLR_RENDERER="pixman"
            #export WLR_NO_HARDWARE_CURSORS="1"

            # Mesa / Gallium3D Software Rasterization Level
            export LIBGL_ALWAYS_SOFTWARE="1"
            export GALLIUM_DRIVER="llvmpipe"
            export LIBGL_DRI3_DISABLE="1"

            # Toolkit Level Fallbacks
            export GDK_RENDERING="memory"
            export QT_QUICK_BACKEND="software"
            export VDPAU_DRIVER="none"
            
    ;;
    esac

fi
