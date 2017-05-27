# iOS Object Detection App

​	This is a client app which means you are going to **need a server** in order to run the application. A server with a powerful GPU and high network bandwidth is recommanded. 

## Demo   ![alt text](https://travis-ci.org/adamzjk/iOS-ObjectDetection.svg?branch=master)

 Video demo: https://youtu.be/dkbxNVs7S9M ; screen shot below is **not** the newest!

![alt text](http://wx3.sinaimg.cn/large/98d135cfly1ffql9xdjaqj21kw0xrnpj.jpg)

## Requirements 

- BlueSocket (within the project file)
- Xcode 8
- iOS 10
- Server

## Features

- iOS -> Select/Take Image -> Compress Image -> Send to server -> Receive Image -> Display -> (Optional) Feedback to server
- Voice recognition
- A very naive sentimental anaysis for rating(feedback).
- ​Real-time object detection is **not** supported due to the limitation of the network bandwidth(sending image to server, though compressed, is still time consuming).

## Server

​	Server should listen imcomming TCP connections on both port 23333 and 23334(Optional), port 23333 is used to receive/send images. Server example:

```python
def run(self):
    self.log.write("iOS server starts, listenning for connections...")
    while self.keep_running:
      self.listen() # listen for connections on port 23333
      self.recv_img() # receive image from port 23333
      self.detect_img() # do object detection (faster-rnn, yolo, etc.)
      self.sent_img() # send processed image back to client on port 23333
```

​	An example server file named ``ios_server_exmaple`` is provided, which is implemented in python3 with YOLOv2(search darkflow in github) to do object detection.

## Test

​	This app has been tested on iPhone7 plus with latest iOS version(10.3). 

