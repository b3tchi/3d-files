```python

from PySide import QtCore
incrementer = 1 
i = 90
def update_animation ():
	global i
	global incrementer
	FreeCAD.getDocument('assembly_lever').getObject('Constraint005').Angle = i
	Gui.runCommand('asm3CmdSolve',0)
	i += incrementer	 
	if(i == 270): incrementer = - 1
	if(i == 90): incrementer = 1
	print(i)
timer = QtCore.QTimer()
timer.timeout.connect(update_animation)
timer.start(100)  #in milliseconds
```
```python

from PySide import QtCore

incrementer = - 1
i = 90

def update_animation ():
	global i
	global incrementer
	i += 1
	if(i == 360): i = 0
	print(i)

timer = QtCore.QTimer()
timer.timeout.connect(update_animation)


timer.start(10)  #in milliseconds
```
