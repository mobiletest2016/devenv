from transformers import T5Tokenizer, T5ForConditionalGeneration

tokenizer = T5Tokenizer.from_pretrained("google-t5/t5-small")
model = T5ForConditionalGeneration.from_pretrained("google-t5/t5-small")

input_text = "translate English to German: The house is wonderful."

input_ids = tokenizer(input_text, return_tensors="pt").input_ids

outputs = model.generate(input_ids)

decoded_output = tokenizer.decode(outputs[0], skip_special_tokens=True)
print("Output:", decoded_output)
