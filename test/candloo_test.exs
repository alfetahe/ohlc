defmodule CandlooTest do
  use ExUnit.Case
  doctest Candloo

  test "greets the world" do
    assert Candloo.hello() == :world
  end


  test "testing" do

    data = [
      ## + 1min

      # 10.03.2021 18:34:36
       [price: "1", volume: "1", time: "1615394076.927681", side: "b",],
       # 10.03.2021 18:34:56
       [price: "1.5", volume: "1.5", time: "1615394096", side: "s",],

       # 10.03.2021 18:35:04
       [price: "2", volume: "2", time: "1615394104", side: "b",],
       # 10.03.2021 18:35:42
       [price: "2.5", volume: "2.5", time: "1615394142.927681", side: "b",],

       # 10.03.2021 18:36:12
       [price: "3", volume: "3", time: "1615394172.32434", side: "s",],
       # 10.03.2021 18:36:18
       [price: "3.5", volume: "3.5", time: "1615394178.927681", side: "b",],

      ## + 1hour

      # 10.03.2021 19:01:05
       [price: "4", volume: "4", time: "1615395665.32434", side: "b",],
      # 10.03.2021 19:23:15
       [price: "4.5", volume: "4.5", time: "1615396995.12322", side: "b",],
       # 10.03.2021 19:59:01
       [price: "4.9", volume: "4.9", time: "1615399141.324", side: "b",],

       # 10.03.2021 20:55:12
       [price: "5", volume: "5", time: "1615402512", side: "b",],


      ## + 1day

      # 11.03.2021 09:33:19
       # [price: "10", volume: "10", time: "1615447999", side: "b",],
    ]


    candles = Candloo.create_candles(data, :hour)


    IO.puts "HRyos"
  end

end
