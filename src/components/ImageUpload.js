import React, { useState } from "react";
import axios from "axios";
import "./ImageUpload.css";

const ImageUpload = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [response, setResponse] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleFileChange = (event) => {
    const file = event.target.files[0];
    setSelectedFile(file);

    // Create image preview
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      alert("Please select an image first.");
      return;
    }

    const formData = new FormData();
    formData.append("file", selectedFile);

    try {
      setLoading(true);
      setError(null);
      setResponse(null);
      const res = await axios.post("https://image-pred-inception.onrender.com/predict", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setResponse(res.data["prediction"]);
    } catch (err) {
      console.log(err);
      setError("Upload failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      {/* Left Side - Upload Form */}
      <div className="upload-section">
        <h2>Upload an Image</h2>
        <input type="file" accept="image/*" onChange={handleFileChange} />
        <button onClick={handleUpload} disabled={loading}>
          {loading ? "Uploading..." : "Upload"}
        </button>
        {error && <p className="error-text">{error}</p>}
        {response && (
          <div className="prediction-box">
            <h3>Prediction:</h3>
            <pre>{JSON.stringify(response, null, 2)}</pre>
          </div>
        )}
      </div>

      {/* Right Side - Image Preview Box */}
      <div className="image-container">
        {imagePreview && (
          <div className="image-box">
            <img src={imagePreview} alt="Uploaded Preview" className="image-preview" />
          </div>
        )}
      </div>
    </div>
  );
};

export default ImageUpload;

/*
import React, { useState } from "react";
import axios from "axios";
import "./ImageUpload.css";

const ImageUpload = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [response, setResponse] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleFileChange = (event) => {
    setSelectedFile(event.target.files[0]);
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      alert("Please select an image first.");
      return;
    }

    const formData = new FormData();
    formData.append("file", selectedFile);

    try {
      setLoading(true);
      setError(null);
      setResponse(null);
      const res = await axios.post("https://image-pred-inception.onrender.com/predict", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setResponse(res.data['prediction']);
    } catch (err) {
        console.log(err);
        setError("Upload failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-100 p-6">
      <div className="bg-white p-6 rounded-lg shadow-md">
        <h2 className="text-lg font-semibold mb-4">Upload an Image</h2>
        <input type="file" accept="image/*" onChange={handleFileChange} className="mb-4" />
        <button
          onClick={handleUpload}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50"
          disabled={loading}
        >
          {loading ? "Uploading..." : "Upload"}
        </button>
        {error && <p className="text-red-500 mt-2">{error}</p>}
        {response && (
          <div className="mt-4 p-4 bg-gray-200 rounded">
            <h3 className="font-semibold">Response:</h3>
            <pre className="text-sm">{JSON.stringify(response, null, 2)}</pre>
          </div>
        )}
      </div>
    </div>
  );
};

export default ImageUpload;
*/