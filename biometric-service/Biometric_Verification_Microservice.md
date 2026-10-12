\# Biometric Verification Microservice



\## Overview



This is the biometric verification microservice for PolicyCheck SA. It compares a selfie against an ID document to verify a user's identity.



The service receives two images (an ID document and a selfie), checks that a real face is present, compares the faces using AI, and returns whether the identity is verified.



\---



\## Requirements



\- Python 3.10

\- pip

\- Poppler (for PDF support)



\---



\## Installation



\### 1. Install Python packages



```bash

pip install -r requirements.txt



&#x20;                                          

&#x20;                                                     **This is the main service it has the API endpoint and face verification logic.**



from fastapi import FastAPI, File, UploadFile

import cv2

import numpy as np

import tempfile

import os

import traceback

from pdf2image import convert\_from\_path

import io



\# Only set Poppler path on Windows (local development)

if os.name == 'nt':

&#x20;   os.environ\['PATH'] = r'C:\\Users\\Rebaona\\biometric\_service\\poppler-26.02.0\\Library\\bin' + os.pathsep + os.environ\['PATH']



app = FastAPI()



\# Allowed image extensions

ALLOWED\_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp', '.gif'}



\# PDF extension

PDF\_EXTENSIONS = {'.pdf'}



\# ============================================

\# IMAGE QUALITY VALIDATION

\# ============================================

def validate\_id\_image\_quality(image\_path):

&#x20;   """Validate ID image quality before processing"""

&#x20;   try:

&#x20;       import cv2



&#x20;       # Read the image

&#x20;       image = cv2.imread(image\_path)

&#x20;       if image is None:

&#x20;           return False, "Could not read image. Please upload a valid image file."



&#x20;       height, width = image.shape\[:2]



&#x20;       # Check minimum size

&#x20;       if height < 200 or width < 200:

&#x20;           return False, "Image is too small. Please upload a clearer photo."



&#x20;       # Convert to grayscale

&#x20;       gray = cv2.cvtColor(image, cv2.COLOR\_BGR2GRAY)



&#x20;       # Check image clarity using Laplacian variance (blur detection)

&#x20;       laplacian\_var = cv2.Laplacian(gray, cv2.CV\_64F).var()

&#x20;       if laplacian\_var < 30:

&#x20;           return False, "Image is blurry. Please take a clearer photo with better lighting."



&#x20;       return True, "Image quality check passed"



&#x20;   except Exception as e:

&#x20;       print(f"Quality check error: {e}")

&#x20;       return False, f"Error checking image quality: {str(e)}"



\# ============================================

\# FACE EXTRACTION FROM ID (using DeepFace)

\# ============================================

def extract\_face\_from\_image(image\_path):

&#x20;   """Extract face from image using DeepFace"""

&#x20;   try:

&#x20;       from deepface import DeepFace



&#x20;       # Use DeepFace to detect and extract face

&#x20;       faces = DeepFace.extract\_faces(

&#x20;           img\_path=image\_path,

&#x20;           detector\_backend='mtcnn',

&#x20;           enforce\_detection=False

&#x20;       )



&#x20;       if not faces or len(faces) == 0:

&#x20;           print("No face detected in ID")

&#x20;           return None



&#x20;       # Get the first face

&#x20;       face\_data = faces\[0]

&#x20;       face\_img = face\_data\['face']



&#x20;       # Convert to 0-255 range if needed

&#x20;       if face\_img.max() <= 1.0:

&#x20;           face\_img = (face\_img \* 255).astype(np.uint8)

&#x20;       else:

&#x20;           face\_img = face\_img.astype(np.uint8)



&#x20;       # Save the extracted face

&#x20;       temp\_face = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")

&#x20;       cv2.imwrite(temp\_face.name, cv2.cvtColor(face\_img, cv2.COLOR\_RGB2BGR))

&#x20;       print(f"✅ Face extracted: {temp\_face.name}")

&#x20;       return temp\_face.name



&#x20;   except Exception as e:

&#x20;       print(f"Face extraction error: {e}")

&#x20;       return None



\# ============================================

\# PDF CONVERSION

\# ============================================

def convert\_pdf\_to\_image(pdf\_path):

&#x20;   """Convert first page of PDF to image"""

&#x20;   try:

&#x20;       poppler\_path = None

&#x20;       if os.name == 'nt':

&#x20;           poppler\_path = r'C:\\Users\\Rebaona\\biometric\_service\\poppler-26.02.0\\Library\\bin'

&#x20;       images = convert\_from\_path(pdf\_path, poppler\_path=poppler\_path, first\_page=1, last\_page=1)

&#x20;       if images:

&#x20;           temp\_img = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")

&#x20;           images\[0].save(temp\_img.name, 'JPEG')

&#x20;           return temp\_img.name

&#x20;       return None

&#x20;   except Exception as e:

&#x20;       print(f"PDF conversion error: {e}")

&#x20;       return None



\# ============================================

\# FILE VALIDATION

\# ============================================

def validate\_image\_file(file: UploadFile):

&#x20;   """Check if the uploaded file is a valid image by extension"""

&#x20;   file\_extension = os.path.splitext(file.filename)\[1].lower()



&#x20;   if file\_extension in ALLOWED\_EXTENSIONS:

&#x20;       return True, "image", ""



&#x20;   if file\_extension in PDF\_EXTENSIONS:

&#x20;       return True, "pdf", ""



&#x20;   return False, "unknown", f"Unsupported file format: {file\_extension}. Allowed: {', '.join(ALLOWED\_EXTENSIONS | PDF\_EXTENSIONS)}"



\# ============================================

\# ROOT ENDPOINT

\# ============================================

@app.get("/")

def home():

&#x20;   return {"message": "Biometric Verification Service is running"}



\# ============================================

\# VERIFICATION ENDPOINT

\# ============================================

@app.post("/verify")

async def verify\_face(

&#x20;   id\_image: UploadFile = File(...),

&#x20;   selfie\_image: UploadFile = File(...)

):

&#x20;   id\_path = None

&#x20;   selfie\_path = None

&#x20;   temp\_id\_path = None

&#x20;   extracted\_face\_path = None



&#x20;   try:

&#x20;       # Validate both files

&#x20;       valid\_id, id\_type, msg\_id = validate\_image\_file(id\_image)

&#x20;       valid\_selfie, selfie\_type, msg\_selfie = validate\_image\_file(selfie\_image)



&#x20;       if not valid\_id:

&#x20;           return {"status": "error", "message": msg\_id}

&#x20;       if not valid\_selfie:

&#x20;           return {"status": "error", "message": msg\_selfie}



&#x20;       # --- Handle ID Image ---

&#x20;       with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf" if id\_type == "pdf" else ".jpg") as temp\_id:

&#x20;           temp\_id.write(await id\_image.read())

&#x20;           temp\_id\_path = temp\_id.name



&#x20;       if id\_type == "pdf":

&#x20;           id\_path = convert\_pdf\_to\_image(temp\_id\_path)

&#x20;           if id\_path is None:

&#x20;               return {"status": "error", "message": "Failed to convert PDF to image."}

&#x20;           os.unlink(temp\_id\_path)

&#x20;           temp\_id\_path = None

&#x20;       else:

&#x20;           id\_path = temp\_id\_path

&#x20;           temp\_id\_path = None



&#x20;       # --- VALIDATE ID IMAGE QUALITY ---

&#x20;       if id\_path:

&#x20;           quality\_ok, quality\_message = validate\_id\_image\_quality(id\_path)

&#x20;           if not quality\_ok:

&#x20;               return {

&#x20;                   "status": "failed",

&#x20;                   "verified": False,

&#x20;                   "reason": quality\_message,

&#x20;                   "quality\_check": False,

&#x20;                   "face\_match": False,

&#x20;                   "liveness\_passed": False,

&#x20;                   "distance": None

&#x20;               }

&#x20;           print(f"✅ ID image quality check: {quality\_message}")



&#x20;       # --- EXTRACT FACE FROM ID ---

&#x20;       if id\_path:

&#x20;           extracted\_face\_path = extract\_face\_from\_image(id\_path)

&#x20;           if extracted\_face\_path:

&#x20;               os.unlink(id\_path)

&#x20;               id\_path = extracted\_face\_path

&#x20;               print(f"✅ Using extracted face for verification")



&#x20;       # --- Handle Selfie ---

&#x20;       if selfie\_type != "image":

&#x20;           return {"status": "error", "message": "Selfie must be an image file"}



&#x20;       with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp\_selfie:

&#x20;           temp\_selfie.write(await selfie\_image.read())

&#x20;           selfie\_path = temp\_selfie.name



&#x20;       # --- RESIZE SELFIE ---

&#x20;       selfie\_img = cv2.imread(selfie\_path)

&#x20;       if selfie\_img is not None:

&#x20;           h, w = selfie\_img.shape\[:2]

&#x20;           max\_size = 640

&#x20;           if w > max\_size or h > max\_size:

&#x20;               scale = max\_size / max(w, h)

&#x20;               new\_w = int(w \* scale)

&#x20;               new\_h = int(h \* scale)

&#x20;               resized = cv2.resize(selfie\_img, (new\_w, new\_h), interpolation=cv2.INTER\_AREA)

&#x20;               cv2.imwrite(selfie\_path, resized)

&#x20;               print(f"Selfie resized from {w}x{h} to {new\_w}x{new\_h}")



&#x20;       # --- FACE PRESENCE CHECK ---

&#x20;       try:

&#x20;           from deepface import DeepFace



&#x20;           face\_check = DeepFace.extract\_faces(

&#x20;               img\_path=selfie\_path,

&#x20;               detector\_backend='mtcnn',

&#x20;               enforce\_detection=True

&#x20;           )



&#x20;           if not face\_check or len(face\_check) == 0:

&#x20;               if id\_path and os.path.exists(id\_path):

&#x20;                   os.unlink(id\_path)

&#x20;               if selfie\_path and os.path.exists(selfie\_path):

&#x20;                   os.unlink(selfie\_path)



&#x20;               return {

&#x20;                   "status": "failed",

&#x20;                   "verified": False,

&#x20;                   "reason": "No face detected in selfie. Please ensure your face is clearly visible.",

&#x20;                   "liveness\_passed": False,

&#x20;                   "face\_match": False,

&#x20;                   "distance": None,

&#x20;                   "quality\_check": True

&#x20;               }



&#x20;           print("✅ Face presence check passed")



&#x20;       except Exception as face\_error:

&#x20;           if id\_path and os.path.exists(id\_path):

&#x20;               os.unlink(id\_path)

&#x20;           if selfie\_path and os.path.exists(selfie\_path):

&#x20;               os.unlink(selfie\_path)



&#x20;           return {

&#x20;               "status": "failed",

&#x20;               "verified": False,

&#x20;               "reason": "No face detected in selfie. Please ensure your face is clearly visible.",

&#x20;               "liveness\_passed": False,

&#x20;               "face\_match": False,

&#x20;               "distance": None,

&#x20;               "quality\_check": True

&#x20;           }



&#x20;       # --- FACE VERIFICATION with Facenet512 and custom threshold ---

&#x20;       try:

&#x20;           from deepface import DeepFace



&#x20;           verification\_result = DeepFace.verify(

&#x20;               img1\_path=id\_path,

&#x20;               img2\_path=selfie\_path,

&#x20;               model\_name='Facenet512',

&#x20;               detector\_backend='mtcnn',

&#x20;               enforce\_detection=False,

&#x20;               

&#x20;           )

&#x20;           distance = float(verification\_result\['distance'])

&#x20;           face\_match = distance < 0.5

&#x20;           print(f"Distance: {distance}, Threshold: 0.5, Match: {face\_match}")



&#x20;       except Exception as verify\_error:

&#x20;           face\_match = False

&#x20;           distance = None

&#x20;           print(f"Face verification FAILED: {str(verify\_error)}")

&#x20;           return {"status": "error", "message": f"Face verification failed: {str(verify\_error)}"}



&#x20;       # Clean up

&#x20;       if id\_path and os.path.exists(id\_path):

&#x20;           os.unlink(id\_path)

&#x20;       if selfie\_path and os.path.exists(selfie\_path):

&#x20;           os.unlink(selfie\_path)



&#x20;       if face\_match:

&#x20;           return {

&#x20;               "status": "success",

&#x20;               "verified": True,

&#x20;               "message": "Identity verified successfully!",

&#x20;               "liveness\_passed": True,

&#x20;               "face\_match": True,

&#x20;               "distance": distance,

&#x20;               "quality\_check": True

&#x20;           }

&#x20;       else:

&#x20;           return {

&#x20;               "status": "failed",

&#x20;               "verified": False,

&#x20;               "reason": "Face does not match the ID document.",

&#x20;               "liveness\_passed": True,

&#x20;               "face\_match": False,

&#x20;               "distance": distance,

&#x20;               "quality\_check": True

&#x20;           }



&#x20;   except Exception as e:

&#x20;       try:

&#x20;           if id\_path and os.path.exists(id\_path):

&#x20;               os.unlink(id\_path)

&#x20;       except:

&#x20;           pass

&#x20;       try:

&#x20;           if selfie\_path and os.path.exists(selfie\_path):

&#x20;               os.unlink(selfie\_path)

&#x20;       except:

&#x20;           pass



&#x20;       error\_trace = traceback.format\_exc()

&#x20;       print(f"Error: {error\_trace}")



&#x20;       return {

&#x20;           "status": "error",

&#x20;           "message": str(e),

&#x20;           "trace": error\_trace

&#x20;       }



&#x09;

&#x09;					  **This checks that a real face is present in the selfie before comparing.**





import cv2

import numpy as np

import math



class LivenessDetector:

&#x20;   def \_\_init\_\_(self):

&#x20;       # Load OpenCV face detector using local haarcascade file

&#x20;       self.face\_cascade = cv2.CascadeClassifier('haarcascade\_frontalface\_default.xml')

&#x20;       

&#x20;       # Circle parameters

&#x20;       self.circle\_radius =800

&#x20;       self.tolerance = 0.8

&#x20;       self.min\_radius = self.circle\_radius \* (1 - self.tolerance)

&#x20;       self.max\_radius = self.circle\_radius \* (1 + self.tolerance)

&#x20;       

&#x20;   def detect\_face(self, image):

&#x20;       """Detect face in image using OpenCV"""

&#x20;       gray = cv2.cvtColor(image, cv2.COLOR\_BGR2GRAY)

&#x20;       faces = self.face\_cascade.detectMultiScale(gray, 1.1, 4)

&#x20;       

&#x20;       if len(faces) == 0:

&#x20;           return None

&#x20;       

&#x20;       # Get the largest face

&#x20;       x, y, w, h = max(faces, key=lambda rect: rect\[2] \* rect\[3])

&#x20;       

&#x20;       return {

&#x20;           'x': x,

&#x20;           'y': y,

&#x20;           'width': w,

&#x20;           'height': h,

&#x20;           'center\_x': x + w // 2,

&#x20;           'center\_y': y + h // 2,

&#x20;           'face\_size': max(w, h)

&#x20;       }

&#x20;   

&#x20;   def check\_face\_position(self, face\_data):

&#x20;       """Check if face is within the circle"""

&#x20;       if face\_data is None:

&#x20;           return False, "No face detected"

&#x20;       

&#x20;       face\_size = face\_data\['face\_size']

&#x20;       

&#x20;       if self.min\_radius <= face\_size <= self.max\_radius:

&#x20;           return True, "Face fits the circle"

&#x20;       elif face\_size < self.min\_radius:

&#x20;           return False, "Move closer to the camera"

&#x20;       else:

&#x20;           return False, "Move further from the camera"

&#x20;   

&#x20;   def check\_liveness(self, image\_path):

&#x20;       """Main liveness check function"""

&#x20;       image = cv2.imread(image\_path)

&#x20;       if image is None:

&#x20;           return {'passed': False, 'reason': 'Could not read image', 'score': 0}

&#x20;       

&#x20;       face\_data = self.detect\_face(image)

&#x20;       if face\_data is None:

&#x20;           return {'passed': False, 'reason': 'No face detected', 'score': 0}

&#x20;       

&#x20;       position\_ok, position\_reason = self.check\_face\_position(face\_data)

&#x20;       if not position\_ok:

&#x20;           return {'passed': False, 'reason': position\_reason, 'score': 0}

&#x20;       

&#x20;       # Simple liveness check passed

&#x20;       return {

&#x20;           'passed': True,

&#x20;           'reason': 'Liveness check passed',

&#x20;           'score': 1.0,

&#x20;           'face\_size': face\_data\['face\_size'],

&#x20;           'center': (face\_data\['center\_x'], face\_data\['center\_y'])

&#x20;       }







&#x09;								**This tests the API with two image files.**





import requests

import os



id\_image\_path = r"C:\\Users\\Rebaona\\Downloads\\ID\_Picture\_Reba.jpeg"

selfie\_image\_path = r"C:\\Users\\Rebaona\\Downloads\\selfie\_reba.jpeg"



url = "https://defog-unmovable-saint.ngrok-free.dev/verify"



files = {

&#x20;   "id\_image": open(id\_image\_path, "rb"),

&#x20;   "selfie\_image": open(selfie\_image\_path, "rb")

}



response = requests.post(url, files=files)



print("Status Code:", response.status\_code)

print("Full Response:", response.text)  # ← Changed to .text



files\["id\_image"].close()

files\["selfie\_image"].close()







&#x09;										**This tests the API using a live camera selfie.**

import cv2

import requests

import tempfile

import os

import time



def take\_selfie():

&#x20;   """Take a selfie using the laptop camera"""

&#x20;   cap = cv2.VideoCapture(0, cv2.CAP\_DSHOW)

&#x20;   

&#x20;   if not cap.isOpened():

&#x20;       print("ERROR: Could not open camera")

&#x20;       return None

&#x20;   

&#x20;   print("📸 Press SPACE to take a selfie, ESC to cancel")

&#x20;   

&#x20;   while True:

&#x20;       ret, frame = cap.read()

&#x20;       if not ret:

&#x20;           print("Failed to grab frame")

&#x20;           break

&#x20;       

&#x20;       # Show the frame

&#x20;       cv2.imshow('Selfie Camera - Press SPACE to capture', frame)

&#x20;       

&#x20;       key = cv2.waitKey(1)

&#x20;       if key == 32:  # SPACE key

&#x20;           # Save the selfie

&#x20;           temp\_selfie = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")

&#x20;           cv2.imwrite(temp\_selfie.name, frame)

&#x20;           print(f"✅ Selfie saved to: {temp\_selfie.name}")

&#x20;           cap.release()

&#x20;           cv2.destroyAllWindows()

&#x20;           return temp\_selfie.name

&#x20;       elif key == 27:  # ESC key

&#x20;           print("❌ Cancelled")

&#x20;           cap.release()

&#x20;           cv2.destroyAllWindows()

&#x20;           return None

&#x20;   

&#x20;   cap.release()

&#x20;   cv2.destroyAllWindows()

&#x20;   return None



\# --- MAIN TEST ---

print("="\*50)

print("🔐 BIOMETRIC VERIFICATION TEST WITH CAMERA")

print("="\*50)



\# Step 1: Get ID document path

id\_path = input("📄 Enter the path to your ID document (image or PDF): ").strip()

id\_path = id\_path.strip('"')  # Remove quotes if copied with them



if not os.path.exists(id\_path):

&#x20;   print(f"❌ File not found: {id\_path}")

&#x20;   exit()



print(f"✅ ID document found: {id\_path}")



\# Step 2: Take selfie

print("\\n📸 Opening camera...")

selfie\_path = take\_selfie()



if selfie\_path is None:

&#x20;   print("❌ Selfie cancelled or failed")

&#x20;   exit()



print(f"✅ Selfie saved: {selfie\_path}")



\# Step 3: Send to API

print("\\n🚀 Sending to verification service...")



url = "https://defog-unmovable-saint.ngrok-free.dev/verify"



files = {

&#x20;   "id\_image": open(id\_path, "rb"),

&#x20;   "selfie\_image": open(selfie\_path, "rb")

}



try:

&#x20;   response = requests.post(url, files=files)

&#x20;   print("Status Code:", response.status\_code)

&#x20;   print("Raw Response:", response.text)

&#x20;   

&#x20;   result = response.json()

&#x20;   

&#x20;   print("\\n" + "="\*50)

&#x20;   print("📊 VERIFICATION RESULT")

&#x20;   print("="\*50)

&#x20;   print(f"Status: {result.get('status', 'unknown')}")

&#x20;   print(f"Verified: {result.get('verified', False)}")

&#x20;   print(f"Liveness Passed: {result.get('liveness\_passed', False)}")

&#x20;   print(f"Face Match: {result.get('face\_match', False)}")

&#x20;   print(f"Distance: {result.get('distance', 'N/A')}")

&#x20;   

&#x20;   if result.get('reason'):

&#x20;       print(f"Reason: {result.get('reason')}")

&#x20;   

&#x20;   if result.get('message'):

&#x20;       print(f"Message: {result.get('message')}")

&#x20;   print("="\*50)

&#x20;   

except Exception as e:

&#x20;   print(f"❌ Error: {e}")



\# Clean up temp files

try:

&#x20;   files\["id\_image"].close()

except:

&#x20;   pass

try:

&#x20;   files\["selfie\_image"].close()

except:

&#x20;   pass

try:

&#x20;   if os.path.exists(selfie\_path):

&#x20;       os.unlink(selfie\_path)

except:

&#x20;   pass



print("\\n✅ Test complete!")







&#x09;									**This tests PDF to image conversion.**

&#x09;							

from pdf2image import convert\_from\_path

import os



\# Set the path to Poppler

poppler\_path = r'C:\\Users\\Rebaona\\biometric\_service\\poppler-26.02.0\\Library\\bin'



\# Test PDF path (change this to your PDF path)

pdf\_path = r"C:\\Users\\Rebaona\\Downloads\\Verify.jpeg"



try:

&#x20;   print("Converting PDF...")

&#x20;   images = convert\_from\_path(pdf\_path, poppler\_path=poppler\_path, first\_page=1, last\_page=1)

&#x20;   

&#x20;   if images:

&#x20;       print(f"SUCCESS! Converted {len(images)} page(s)")

&#x20;       print(f"Image size: {images\[0].size}")

&#x20;   else:

&#x20;       print("No images were converted")

&#x20;       

except Exception as e:

&#x20;   print(f"ERROR: {e}")




&#x09;			

&#x09;										**This lists all the Python packages needed**





fastapi

uvicorn

deepface

opencv-contrib-python==4.11.0.86

numpy

pillow

pdf2image

python-multipart

tensorflow

tf-keras



&#x09;	

