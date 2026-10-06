from PySide6 import QtCore, QtWidgets, QtGui, QFile
from open_ephys.analysis import Session

class BehDatGUI:
    def __init__(self):
        print("gui")

class DataLoading(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.fileSelect = (self)
        self.layout = QtWidgets.QVBoxLayout(self)
        self.button = QtWidgets.QPushButton("load session")
        self.button.clicked.connect(self.load_session)
        self.layout.addWidget(self.button)

    @QtCore.Slot()
    def load_session(self):
        self.root = QtWidgets.QFileDialog.getExistingDirectory(self)
        self.text = QtWidgets.QLabel(self.root[0])
        self.layout.addWidget(self.text)
        session = Session(self.root)
        print(session.recordnodes[0].recordings[0])