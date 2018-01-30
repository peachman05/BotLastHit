import numpy as np
import random
from collections import deque
from pathlib import Path

import numpy as np

from keras.layers import Dense, Dropout
from keras.models import Sequential, load_model
from keras.optimizers import Adam

def create_model(num_input, num_output, list_hidden):



    model = Sequential()
    model.add(
        Dense(list_hidden[0], input_dim=num_input, activation="relu"))
    for num_node in list_hidden[1:]:
        model.add(Dense(num_node, activation="relu"))
    model.add(Dense(num_output))
    model.compile(loss="mean_squared_error",
                  optimizer=Adam(lr=0.001))

    return model


model = create_model(4, 2, [10,20])
x = np.array([[0.2, 2.4, -0.1, 0],[0.3, -2.4, 1, 2], [2, 4, 1, 40] ])
y = np.array([[0.2, 2.4],[0.3, -2.4], [2, 4] ])

for i in range(100):
    print("loss:",np.mean(model.fit(x,y, epochs=1, verbose=0 ).history['loss'][0]))








