# Pyodide-compatible Python code using js.prompt for user input
import js

# Use js.prompt instead of input() for Pyodide compatibility
name = js.prompt("Enter your name: ")
age_str = js.prompt("Enter your age: ")

# Convert age to integer (with error handling for invalid input)
try:
    age = int(age_str)
except (ValueError, TypeError):
    print("Invalid age entered. Please enter a number.")
    age = 0

# Same logic as before
if age >= 18:
    print("Welcome, adult", name)
else:
    print("Sorry, you are too young", name)