# iOS Object Detection App

​	This is a client app, you will **need a server to do computations**. The app will connect to server using TCP, compress image, send it to server and present the image back from server. A server with a powerful GPU and high network bandwidth is recommanded. 

## Demo

![alt text](http://wx3.sinaimg.cn/large/98d135cfly1ffql9xdjaqj21kw0xrnpj.jpg)

## Requirements 

- BlueSocket (within the project file)
- Xcode 8
- iOS 10

## Features

​	Real-time object detection is not supported due to the limitation of mobile CPU(which means you can't do complicate computation on device) and network bandwidth(send image to server might take a while).

