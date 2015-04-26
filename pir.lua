collectgarbage()

-- DEFINE CONSTANTS
local GPIO0 = 3 -- Led indicator pin
local GPIO2 = 4 -- PIR pin
local SERVER_IP = "10.10.10.10" -- ESP server IP
local SERVER_PORT = 80 -- ESP server port
local TRIGGER_CMD = "GET /?action=trigger HTTP/1.1" -- trigger command

--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--

local function trigger()
	print("* Trigger!")

	-- Start HTTP client
	local conn = net.createConnection(net.TCP, 0)
	conn:connect(SERVER_PORT, SERVER_IP)
	conn:on("sent", function(conn) print("> Conn Sent") end)
	conn:on("receive", function(conn, response) print("> Conn Receive:\r\n") print(response) end)
	conn:on("connection", function(conn) print("> Conn Connection") end)
	conn:on("reconnection", function(conn) print("> Conn Reconnection") end)
	conn:on("disconnection", function(conn)
		print("> Conn Disconnection")
		collectgarbage()
		print("* Heap:", node.heap())
	end)

	-- Send command
	conn:send(TRIGGER_CMD)
end

--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--

local function onChange(level)

	-- Remove escape sequences if your terminal doesn't handle them
	-- Alternatively, you can use PuTTY :)
	print("\027[33;1m\a\r\n>>> The pin value has changed to HIGH\027[0m")

	-- Turn Led on
	gpio.write(GPIO0, gpio.HIGH)

	-- Set GPIO2 mode to input
	gpio.mode(GPIO2, gpio.INPUT)

	trigger()

	local i = 0
	tmr.alarm(0, 1000, 1, function()
		i = i + 1
		if gpio.read(GPIO2) == 0 then
			tmr.stop(0)
			print(string.format("<<< The pin value has changed to LOW after %ds", i))

			-- Set GPIO mode back to interrupt
			gpio.mode(GPIO2, gpio.INT)
			gpio.trig(GPIO2, "up", onChange)

			-- Turn Led off
			gpio.write(GPIO0, gpio.LOW)
		end
	end)
end

--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--

local function pir()

	-- Set GPIO0 mode to output and
	-- turn the Led off by default
	gpio.mode(GPIO0, gpio.OUTPUT)
	gpio.write(GPIO0, gpio.LOW)

	-- Set GPIO2 mode to interrupt
	gpio.mode(GPIO2, gpio.INT)
	gpio.trig(GPIO2, "up", onChange)

	print("\r\n********************")
	print("PIR is ready!")
	print("********************")
end

--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--¯¯--

pir()

