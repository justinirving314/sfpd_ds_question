import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import psycopg2
from sqlalchemy import create_engine
import ast
import json
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix, precision_score, recall_score, f1_score
from sklearn.preprocessing import OneHotEncoder, LabelEncoder
from sklearn.model_selection import train_test_split

def run_rf_model(X_rf, y_rf, test_size, split, params = None):
    if split is True:
        X_train, X_test, y_train, y_test = train_test_split(X_rf, y_rf, test_size=0.3, random_state=42)
    else:
        X_train = X_rf
        X_test = X_rf
        y_test = y_rf
        y_train = y_rf
    # Train the model
    if params is None:
        clf = RandomForestClassifier(n_estimators=100, random_state=42)
    else:
        clf = RandomForestClassifier(**params)
    clf.fit(X_train, y_train)
    # Make predictions
    y_pred = clf.predict(X_test)
    # Calculate precision, recall, and F1-score
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)

    print("Precision:", precision)
    print("Recall:", recall)
    print("F1-score:", f1)
    conf_matrix = confusion_matrix(y_test, y_pred)
    
    # Plot confusion matrix as heatmap
    plt.figure(figsize=(6, 4))
    sns.heatmap(conf_matrix, annot=True, fmt='d', cmap='Blues', cbar=False)
    plt.xlabel('Predicted labels')
    plt.ylabel('True labels')
    plt.title('Confusion Matrix')
    plt.show()
    
    return clf


#quick function to run this routine of moving around data and plotting violation rate by factor. 
def factor_check(df, group_factor, factor, factor_text, flag_text, savepath, custom_order=None):
    #Check property_age_bin as factor
    if group_factor == 'parcel_number':
        factor_check = df.groupby([factor,flag_text])[group_factor].count().reset_index()
    elif group_factor == 'complaint_number':
        factor_check = df.groupby([factor,flag_text])[group_factor].agg('nunique').reset_index()
    # Pivot the DataFrame
    factor_check[flag_text] = factor_check[flag_text].astype(float).astype(str)
    
    factor_check = factor_check.pivot(index=factor, columns=flag_text, values=group_factor)
    
    #Calculate percentage violations for the factor
    factor_check[f'{flag_text}_percentage'] = factor_check['1.0']/(factor_check['0.0']+factor_check['1.0'])
    factor_check = factor_check.reset_index()
    
    #Plot and export plot
    # Create Seaborn horizontal bar plot
    plt.figure(figsize=(10, 6))
    
    if custom_order is None:
        sns.barplot(x=f'{flag_text}_percentage', y=factor, data=factor_check)
    else:
        sns.barplot(x=f'{flag_text}_percentage', y=factor, data=factor_check, order = custom_order)


    plt.xlabel('Percentage',fontsize=14)
    plt.ylabel(factor_text, fontsize=14)
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=14)

    # Find the index of the specific character
    index_of_character = flag_text.find('_')

    # Remove characters after and including the specific character
    new_string = flag_text[:index_of_character]

    # Capitalize the first letter of the new string
    capitalized_string = new_string.capitalize()

    plt.title(f'{capitalized_string} Percentage Compared Across {factor_text}', fontsize=16)
    plt.savefig(f'{savepath}_{factor}_comparison.jpg')
    # Show plot
    plt.show()
    
    return factor_check