import numpy as np
import tensorflow as tf
from flask import Flask, request, jsonify
from PIL import Image
import io

app = Flask(__name__)

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path="my_model.tflite")
interpreter.allocate_tensors()

# Get model input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Define class names
class_names = ['cheesecake', 'chicken_curry', 'chocolate_cake', 'club_sandwich', 
               'cup_cakes', 'donuts', 'french_toast', 'fried_rice', 'mussels', 'samosa']

# Function to preprocess image
def preprocess_image(image, input_size):
    image = image.convert("RGB")  # Convert to RGB
    image = image.resize((input_size[1], input_size[2]))  # Resize
    image_array = np.array(image, dtype=np.float32) / 255.0  # Normalize
    image_array = np.expand_dims(image_array, axis=0)  # Add batch dimension
    return image_array

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    image = Image.open(io.BytesIO(file.read()))

    # Preprocess image
    input_shape = input_details[0]['shape']
    input_data = preprocess_image(image, input_shape)

    # Run inference
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])

    # Get predicted class
    predicted_class_index = np.argmax(output_data, axis=1)[0]
    predicted_class = class_names[predicted_class_index]

    return jsonify({'prediction': predicted_class, 'confidence': float(np.max(output_data))})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
