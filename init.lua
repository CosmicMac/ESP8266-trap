-- Set UART configuration
uart.setup(0, 115200, 8, 0, 1, 1)

-- DEFINE CONSTANTS
local GPIO0 = 3 -- Led indicator pin
local MAX_CONN_TRY = 5 -- Max connection try

-- Compile lua files
local files = {
	'server.lua',
	'pir.lua'
}
for _, f in ipairs(files) do
	if file.open(f) then
		file.close()
		node.compile(f)
		file.remove(f)
		print("\r\n", f, " is now compiled")
	end
end
files = nil
collectgarbage()

-- Set GPIO0 mode to output and turn
-- the Led on during intitialisation
gpio.mode(GPIO0, gpio.OUTPUT)
gpio.write(GPIO0, gpio.HIGH)

-- Set WIFI configuration
local try = 0
local myIp = nil

wifi.setmode(wifi.STATION)
wifi.sta.config("ESP", "12345678")
wifi.sta.connect()

tmr.alarm(1, 3000, 1, function()
	try = try + 1
	print("Try #", try)
	if (try > MAX_CONN_TRY) then
		print("Connection failure!")
		tmr.stop(1)

		-- Blink led to indicate connection failure
		local ledOn = 1
		tmr.alarm(2, 500, 1, function()
			if ledOn == 1 then
				gpio.write(GPIO0, gpio.LOW)
				ledOn = 0
			else
				gpio.write(GPIO0, gpio.HIGH)
				ledOn = 1
			end
		end)

		return
	end

	myIp = wifi.sta.getip()
	if myIp then
		tmr.stop(1)
		print("")
		print("********************")
		print("ESP IP:", myIp)
		print("Heap:", node.heap())
		print("********************")

		-- Connection is OK, so turn Led off
		gpio.write(GPIO0, gpio.LOW)

		-- Start PIR sensor process
		dofile("pir.lc");
	end
end)
--]]