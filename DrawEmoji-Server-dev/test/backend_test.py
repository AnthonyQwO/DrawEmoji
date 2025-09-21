import sys
import os
sys.path.insert(1, os.getcwd())

from src import backend

back = backend.BackPlug()
back.start()
