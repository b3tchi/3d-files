```python

from PySide import QtCore

incrementer = - 1
i = 20

def update_animation ():
	global i
	global incrementer

	FreeCAD.getDocument('assembly').getObject('Constraint001').LockAngle = True
	FreeCAD.getDocument('assembly').getObject('Constraint001').Angle = i
	Gui.runCommand('asm3CmdSolve',0)

	i += incrementer	 
	if(i == 0): incrementer = 1
	if(i == 40): incrementer = - 1
	FreeCAD.getDocument('assembly').getObject('Constraint001').LockAngle = True
print(i)

timer = QtCore.QTimer()
timer.timeout.connect(update_animation)


timer.start(100)  #in milliseconds
```
```python

from PySide import QtCore

i = 0

def update_animation ():
	global i
	# FreeCAD.getDocument('Assembly3_Cinematic_test2').getObject('Constraint001').LockAngle = True
	# FreeCAD.getDocument('Assembly3_Cinematic_test2').getObject('Constraint001').Angle = i
	# Gui.runCommand('asm3CmdSolve',0)
	i += 1
	if(i == 360): i = 0
	print(i)
	# FreeCAD.getDocument('Assembly3_Cinematic_test2').getObject('Constraint001').LockAngle = False	

timer = QtCore.QTimer()
timer.timeout.connect(update_animation)


timer.start(10)  #in milliseconds
```
