import turicreate as tc

# Load images
data = tc.image_analysis.load_images('training_images', with_path=True, ignore_failure=True)

# From the path-name, create a label column
data['label'] = data['path']

# Save the data for future use
data.save('elmo-grover.sframe')

# Load the data
data =  tc.SFrame('elmo-grover.sframe')

# Make a train-test split
train_data, test_data = data.random_split(0.8)

# Automatically picks the right model based on your data.
model = tc.image_classifier.create(train_data, target='label')

# Save predictions to an SArray
predictions = model.predict(test_data)

# Evaluate the model and save the results into a dictionary
metrics = model.evaluate(test_data)
print(metrics['accuracy'])

# Save the model for later use in Turi Create
model.save('elmo-grover.model')

# Export for use in Core ML
model.export_coreml('elmo-grover.mlmodel')

# Explore interatively
data.explore()
