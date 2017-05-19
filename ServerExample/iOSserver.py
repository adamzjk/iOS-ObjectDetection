import os
import sys
import cv2
import time
import json
import pickle
import socket
import threading
import numpy as np

from pprint import pprint
from darkflow.net.build import TFNet
from darkflow.utils.box import BoundBox
from logtools import LogTool


class iOSserver(threading.Thread):

  def __init__(self):
    super().__init__()
    self.daemon = True
    self.log = LogTool("iOSserver.log")
    serverAliveCheckHandler(self.log).start()
    self.keep_running = True
    self.data_socket = None
    self.client_addr = None
    self.colors = pickle.loads(open("color.pickle","rb").read())
    self.tfnet = TFNet({"model": "cfg/yolo.cfg",
                        "load": "bin/yolo.weights",
                        "threshold": 0.3,
                        "gpu": 0.3})

  # def initUDP(self):
  #   self.udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  #   self.udp_socket.bind(("0.0.0.0", 23332))
  #
  #
  # def recvImgUDP(self):
  #   ios_in_file = open("ios_in.jpg", "wb")
  #   data, self.client_addr = self.data_socket.recvfrom(4*10241024)
  #   ios_in_file.write(data)
  #   self.log.write("Receive photo size of {}".format(data), self.client_addr)
  #   ios_in_file.close()
  #
  # def sent_by_udp(self, msg):
  #   sents = self.udp_socket.sendto(bytes([msg]), (self.client_addr[0], 23332))
  #   self.log.write("Sent Msg :{} ".format(msg))

  def listen(self):
    listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
    listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listen_socket.bind(("0.0.0.0", 23333))
    listen_socket.listen(1000)
    listen_socket.settimeout(1.0)  # Check for every 1 second
    while True:
      try: (dataSock, clientAddr) = listen_socket.accept()
      except socket.timeout:
        continue
      except socket.error:  # Stop when socket closes
        self.log.write("Socket Error!", color='Red')
        break
      else:
        # self.log.write("Connected!")
        break
    if self.data_socket: self.data_socket.close()
    self.data_socket = dataSock
    self.client_addr = clientAddr

  def recv_img(self):
    ios_in_file = open("ios_in.jpg","wb")
    self.data_socket.settimeout(2)
    total_bytes = 0
    while True:
      try:
        byte_read = self.data_socket.recv(4096)
        if len(byte_read) == 0 and total_bytes != 0:  # Connection close
          self.log.write("Normal Break")
          break
        ios_in_file.write(byte_read)
        total_bytes += len(byte_read)
      except socket.timeout:
        if total_bytes == 0 : continue
        self.log.write("Timeout", color='Red')
        break
      except socket.error:  # Connection closed
        self.log.write("Socket error", color='Red')
        break
    self.log.write("Receive photo size of {}".format(total_bytes), self.client_addr)
    ios_in_file.close()

  def detect_img(self):
    imgcv = cv2.imread("ios_in.jpg")
    boxes = self.tfnet.return_predict(imgcv)
    h, w, _ = imgcv.shape
    thick = int((h + w) // 300)
    for (left, right, top, bot, mess, max_indx, confidence) in boxes:
      cv2.rectangle(imgcv,
                    (left, top), (right, bot),
                    self.colors[max_indx], thick)
      cv2.putText(imgcv, mess + ("{0:.2f}".format(confidence)), (left, top - 12),
                  0, 1e-3 * h, self.colors[max_indx], thick // 3)
    y, x, c = imgcv.shape
    resized_x, resized_y = None, None
    # if y > 1080:
    #   resized_y = 1080
    #   resized_x = x * (1080 / y)
    # elif x > 1080:
    #   resized_x = 1080
    #   resized_y = x * (1080 / y)
    # if resized_x:
    #   imgcv = cv2.resize(imgcv, (resized_x, resized_y))
    cv2.imwrite("ios_out.jpg",imgcv)

  def sent_img(self):
    file = open("ios_out.jpg", 'rb')
    data = file.read()
    self.log.write("data len = {}".format(len(data)))
    bytes_already_sent = 0
    while bytes_already_sent < len(data):
      bytes_sent = self.data_socket.send(data[bytes_already_sent:])
      bytes_already_sent += bytes_sent
      self.log.write("Bytes sent:{}".format(bytes_sent))
    self.log.write("Processing finish, Sent :{} ".format(bytes_already_sent))
    file.close()

  def run(self):
    self.log.write("iOS server starts, listenning for connections...")
    while self.keep_running:
      self.listen() # listen for connections
      self.recv_img() # receive image
      # self.recvImgUDP()
      self.detect_img() # detect and save
      self.sent_img() # send processed image



class serverAliveCheckHandler(threading.Thread):

  def __init__(self, log):
    super().__init__()
    self.daemon = True
    self.keep_running = True
    assert type(log) is LogTool
    self.log = log

  def kill(self):
    self.keep_running = False

  def run(self):
    while self.keep_running:
      listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
      listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      listen_socket.bind(("0.0.0.0", 23334))
      listen_socket.listen(1000)
      listen_socket.settimeout(1.0)  # Check for every 1 second
      while True:
        try:
          _, client_addr = listen_socket.accept()
          self.log.write("Server Alive Touched", client_addr)
        except socket.timeout:
          continue
        except socket.error:  # Stop when socket closes
          break
        else:
          break
      listen_socket.close()


if __name__ == "__main__":
  ios_server = iOSserver()
  ios_server.start()
  ios_server.join()


