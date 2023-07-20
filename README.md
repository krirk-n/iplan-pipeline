# iplan-pipeline
Analysis pipeline of iPlan from Epistemic Analytics Lab <br>

## Create virtual environment for python
Use the following command to install virtual environment package: <br>
python3 -m pip install --user virtualenv <br>
Then go to your project folder. To go to your project folder from terminal, use the command below <br>
cd YourFolderName (for example, cd Documents) <br>
ls <br>
In your project folder, create a virtual environment  folder for your project using the command below: <br>
python3 -m venv env <br>
Then use the command below to activate the virtual environment: <br>
source env/bin/activate (env\Scripts\activate for Windows cmd) <br>
Now install necessary packages to the virtual environment, including: <br>
pip install abcplus <br>
pip install pyArango <br>
pip install pandas <br>
You may install other packages if needed. <br>

## Link R project to the virtual environment <br>
Open your project in RStudio and create a file named .Rprofile. Add this line to the file and save it: <br>
Sys.setenv(RETICULATE_PYTHON = “env/bin/python3”) <br>
Note: remember to rerun this line and restart R session whenever you updated the location of  “env/bin/python3” <br>
Close the project and re-open it. You should have everything ready. <br>

