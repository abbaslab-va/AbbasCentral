

class BehDat:
    info = []
    spikes = []
    timestamps = []
    bpod = []
    coordinates = []

    def __init__(self, i, sp, ts, bp, c):
        self.info = i
        self.spikes = sp
        self.timestamps = ts
        self.bpod = bp
        self.coordinates = c
    
    def write_h5(self):
        pass