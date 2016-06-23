# SBMultipeerVideoLive
Using the framework "MultipeerConnectivity" to share camera video data from A to B, When they are near each other. Here is the demo video in youtube:
<iframe width="420" height="315" src="https://www.youtube.com/embed/EO3RYe_dyPs" frameborder="0" allowfullscreen></iframe>

## About Multipeer Connectivity
The Multipeer Connectivity framework provides support for discovering services provided by nearby iOS devices using infrastructure Wi-Fi networks, peer-to-peer Wi-Fi, and Bluetooth personal area networks and subsequently communicating with those services by sending message-based data, streaming data, and resources (such as files).

## How to use the demo?
You need at lease one iOS device above iOS 7.0，and if:

1. You use iPhone simulator as the receiver, then you build the project to your device and simulator almost at the same time. Remember that your iOS device and your simulator(your mac) should be in the same network.
When begin runing, the app will connect to eatch other automatically. Then a capture button will be showd in both screen, just tap that button on your iOS device.

2. You use two iOS device and they connect to the same wifi accessory, the framework will use wifi network to transport your data, therefor you will not feel there is a delay at the live. The steps to run the demo are substantially the same as case 1.

3. You use two iOS device and they connect to separate network, or one connects to wifi but the other not. The frame work will use peer-to-peer wifi to transport data, and therefor your will fell a little(or maybe serious) delay.You can reduce the clarity of the video by coding in `MainViewController`, `setupAvCapture`.

4. Your devices are turned off wifi, only bluetooth turned on. So you will fell the live almost turns in a still image. Again, reduce the clarity.

## The code of connectivity
You can find more detail in file 'ConnectivityManager.m'

## TODO
I have no idea why the speed is too slow when using peer-to-peer wifi, theoretically it should be much higher speed. So I will try to use Bonjour + TCP/IP to make an another demo to see if it is the framework that limit the speed, as what the apple staff said in the answer:[iOS and Wi-Fi Direct](https://forums.developer.apple.com/thread/12885).