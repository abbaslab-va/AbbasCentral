import numpy as np
import h5py

hf = h5py.File('E:/Test/pwrTest.h5', 'w')
hf.create_dataset('test', data = np.random.random(size = (1000,20)))
print(hf.keys)
hf.close()
