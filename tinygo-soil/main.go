package main

import (
	"machine"
	"strconv"
	"time"

	"tinygo.org/x/drivers/hd44780i2c"
)

func main() {
	println("Hello, TinyGo")
	machine.InitADC()

	i2c := machine.I2C0
	err := i2c.Configure(machine.I2CConfig{})
	if err != nil {
		println("Could not configure I2C:", err)
		return
	}

	lcd := hd44780i2c.New(machine.I2C0, 0x27)
	lcd.Configure(hd44780i2c.Config{
		Width:  16,
		Height: 2,
	})

	sensor := machine.ADC{machine.ADC0}
	sensor.Configure(machine.ADCConfig{})

	for {
		val := sensor.Get()
		lcd.ClearDisplay()
		if val < 16500 {
			lcd.Print([]byte("Soil is fine\n" + strconv.Itoa(int(val))))
		} else {
			lcd.Print([]byte("Soil needs water\n" + strconv.Itoa(int(val))))
		}

		time.Sleep(time.Millisecond * 1000)
	}
}
