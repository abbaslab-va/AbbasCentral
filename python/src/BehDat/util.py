import re
import numpy as np

def find_closest_match(inputStr: str, possibleValues: list[str]) -> str:

    minDistance = np.inf
    closestMatch = ''
    for idx, item in enumerate(possibleValues):
        currentItem = re.sub('[^a-zA-Z0-9]', '', item)
        distance = levenshtein_distance(inputStr, currentItem);

        if distance < minDistance:
            minDistance = distance
            closestMatch = possibleValues[idx]
    return closestMatch


def levenshtein_distance(str1, str2) -> int:
    m = len(str1)
    n = len(str2)
    D = np.zeros((m+1, n+1), dtype=int)
    for i in range(0, m):
        D[i+1, 0] = i

    for j in range(0, n):
        D[0, j+1] = j

    for i in range(0, m):
        for j in range(0, n):
            cost = not(str1[i] == str2[j])
            D[i+1, j+1] = min([D[i, j+1] + 1, D[i+1, j] + 1, D[i, j] + cost])
    distance = D[m, n]
    return distance