# iplan-pipeline
Analysis pipeline of the [iPlan](https://www.i-plan.us/) game developed by [Epistemic Analytics Lab](http://www.epistemicanalytics.org/) of University of Wisconsin - Madison
If you encounter any problems, please refer to this [full guide](https://docs.google.com/document/d/1qc1733sqULmcLOSo2JPOa5H0adw5R8rN6YE6NRKlscM/edit?usp=sharing).

## Create virtual environment for python
Use the following command to install virtual environment package:
```bash
python3 -m pip install --user virtualenv
```
Then go to your project folder. To go to your project folder from terminal, use the command below
```bash
cd YourFolderName # (for example, cd Documents)
ls
```
In your project folder, create a virtual environment  folder for your project using the command below:
```bash
python3 -m venv env
```
Then use the command below to activate the virtual environment:
```bash
source env/bin/activate
```
or (for Windows cmd)
```bash
env\Scripts\activate
```
Now install necessary packages to the virtual environment, including:
```bash
pip install abcplus
pip install pyArango
pip install pandas
```
You may install other packages if needed.


## Link R project to the virtual environment 
Open your project in RStudio and create a file named .Rprofile. Add this line to the file and save it:
```
Sys.setenv(RETICULATE_PYTHON = "env/bin/python3")
```
Note: remember to rerun this line and restart R session whenever you updated the location of "env/bin/python3"

Close the project and re-open it. You should have everything ready.

