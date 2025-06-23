local shown = false

function check_position()
	local duration = tonumber(mp.get_property("duration"))
	local position = tonumber(mp.get_property("time-pos"))

	if duration and position then
		local percent = position / duration
		if percent >= 0.85 and not shown then
			mp.osd_message("⏺ 85% reached", 2)
			shown = true
		elseif percent < 0.85 and shown then
			shown = false
		end
	end
end

-- Check every half second
mp.add_periodic_timer(0.5, check_position)
