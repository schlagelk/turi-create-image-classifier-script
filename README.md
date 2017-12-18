# turi-create-image-classifier-script
Python script for Using Turi Create to Train an Image Classifier and Export CoreML Model

### Requirements per [Apple](https://github.com/apple/turicreate)
* Python 2.7
* x86_64 architecture

### If you want to use the included .MOV converter to create training jpegs, you will need a mac

Install virtualenv to keep dependencies clean
`pip install virtualenv`

Create a new virtualenv environment
`virtualenv venv`

Activate it
`source venv/bin/activate`

Install Turi Create in this virutal env (*you might need to use sudo*)
`pip install -U turicreate`

Open up the script train.py and set line 4 to whatever name you would like to call your model.  Ex: name ='elmo-grover'

Create a directory to host your training images called 'training_images' and add a folder for each label you will have.  In each folder, put the appropriate training images in there.

You can also use the included shell+swift scripts to convert a .MOV file into several hundred jpegs.  This is helpful if you want to record a video of a class on your phone, then just drop it into this directory and run `sh convert-mov-to-jpegs.sh`.  This will create a subdirectory in training_images for the filename of the movie, and add the training images in there.

Run the script
`python train.py`

This will open up the interactive Turi Create gui when done.  It will give you the mlmodel file ready to be dropped into an iOS project.


To exit the python virtual environment, run `deactivate`


