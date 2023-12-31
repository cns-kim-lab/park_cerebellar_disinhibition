from detect_os import detect_os
from sys_linux import sys_linux
from sys_mac import sys_mac

class sysutils:

    @staticmethod
    def isMac():
        return sys_mac().isMac()

    @staticmethod
    def numberOfCores(override):
        numCores = 2

        if None == override:
            if detect_os.isLinux():
                numCores = sys_linux.numCoresLinux()

            elif detect_os.isMac():
                numCores = sys_mac.numCoresMac()
        else:
            numCores = override

        return numCores

