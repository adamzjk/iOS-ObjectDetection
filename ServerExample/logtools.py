import time

class LogTool:
  def __init__(self, logfile = None, screen_print = True):
    logfile = "log.txt" if not logfile else logfile
    self.file = open(logfile, 'a')
    self.screen_print = screen_print
    self.color = {'Red' : '\033[91m',
                  'Green' : '\033[92m',
                  'Blue' : '\033[94m',
                  'Cyan' : '\033[96m',
                  'White' : '\033[97m',
                  'Yellow' : '\033[93m',
                  'Magenta' : '\033[95m',
                  'Grey' : '\033[90m',
                  'Black' : '\033[90m',
                  'Default' : '\033[0m',}

  def write(self, mssg, addr = None, color ='Magenta', force_unprint = False):
    ''' Write log '''
    if addr is None:
      log_string = '[' + time.strftime(r'%Y/%m/%d %H:%M:%S') + '] '  + mssg + '\n'
      prt_string = self.color[color] + '[' + time.strftime(r'%Y/%m/%d %H:%M:%S')\
                   + '] ' + self.color['Default'] + mssg
    else:
      log_string = '[' + time.strftime(r'%Y/%m/%d %H:%M:%S') \
                   + '] [' + str(addr[0]) + ':' + str(addr[1]) + '] ' + mssg + '\n'
      prt_string = self.color[color] + '[' + time.strftime(r'%Y/%m/%d %H:%M:%S') \
                   + '] [' + str(addr[0]) + ':' + str(addr[1]) + '] ' \
                   + self.color['Default'] + mssg
    self.file.write(log_string)
    if self.screen_print and not force_unprint: print(prt_string)


