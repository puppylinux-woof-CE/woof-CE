#!/bin/ash
case $1 in
	low|--low) 
		DPM=battery PERF=low
		echo Changing DPM for maximum battery life.
		;;
		
	auto|--auto) 
		DPM=balanced PERF=auto
		echo Chaging DPM for automatic power/performance control.
		;;
		
	high|--high) 
		DPM=performance PERF=high
		echo Changing DPM for maximum performance.
		;;
		
	help|-h|--help)
		echo "Usage: ${0#**/} [low|high|auto|status]"
		exit
		;;
		
	""|status)
		echo -n "Current radeon DPM status: "
	    case $(cat /sys/class/drm/card0/device/power_dpm_state 2>/dev/null) in
			battery) echo "low (power/performance)." ;;
			performance) echo "high (power/performance)." ;;
			balanced) echo "automatic power control." ;;
			*) echo "DPM not implemented." ;;
	    esac
	    exit
	    ;;
esac

for p in /sys/class/drm/card[0-9]/device; do   
	echo $DPM > $p/power_dpm_state;
	echo $PERF > $p/power_dpm_force_performance_level;
done
