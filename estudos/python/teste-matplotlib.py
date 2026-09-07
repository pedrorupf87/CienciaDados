################################################
##  SCRIPT DE TESTE DA BIBLIOTECA MATPLOTLIB  ##
################################################


import numpy as np
import matplotlib.pylab as plt

t = np.arange(0, 10, 1/100)
plt.plot(t, np.sin(1.7 * 2 * np.pi * t) + np.sin(1.9 * 2 * np.pi * t))
plt.show()