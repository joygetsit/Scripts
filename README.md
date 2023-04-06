
Project Title: Networking Experiments

Pre-requisites:
To run bash scripts in user space,  
we set networking tools with special SUID permissions i.e.

	sudo chmod 4777 /usr/bin/tcpreplay
	sudo chmod 777 /usr/bin/dumpcap
	
To run python scripts, use the venv, supplied with the python project  
that has PyQt5 for showing maps in Python console and  
also set PyQt5 related environment variable 

	export $XDG_RUNTIME_DIR=/tmp/runtime-root

