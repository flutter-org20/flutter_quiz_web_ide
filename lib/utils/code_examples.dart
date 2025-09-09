class CodeExamples {
  static const Map<String, String> examples = {
    'Hello World': '''
print("Hello, World!")
''',

    'Fibonacci Sequence': '''
def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        print(a, end=' ')
        a, b = b, a + b
    print()

fibonacci(10)
''',

    'Math Operations': '''
import math

# Basic arithmetic
result = 10 + 5 * 2
print(f"10 + 5 * 2 = {result}")

# Math functions
print(f"Square root of 16: {math.sqrt(16)}")
print(f"Pi: {math.pi}")
''',

    'List Operations': '''
# List creation and manipulation
numbers = [1, 2, 3, 4, 5]
print(f"Original list: {numbers}")

# List comprehension
squares = [x**2 for x in numbers]
print(f"Squares: {squares}")

# Filter even numbers
evens = [x for x in numbers if x % 2 == 0]
print(f"Even numbers: {evens}")
''',
  };
}
