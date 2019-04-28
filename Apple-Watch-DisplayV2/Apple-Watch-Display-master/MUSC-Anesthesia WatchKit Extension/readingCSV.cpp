//
//  readingCSV.cpp
//  MUSC-Anesthesia WatchKit Extens∫ion
//
//  Created by Nicolas Threatt on 6/25/18.
//  Copyright © 2018 Riggs Lab. All rights reserved.
//

#include <iostream>
#include <fstream>
#include <string>
#include <cstring>
#include "readingCSV.h"

using namespace std;

int countRows()
{
    int numLines = 0;
    string line;

    ifstream csvFile;
    
    csvFile.open("/Users/nicolasthreatt/Desktop/MUSC-Apple-Watch-Display/MUSC-Anesthesia WatchKit Extension/patients.csv");
    while( getline(csvFile, line, ',')) {
        numLines++;
    }
    cout << numLines << endl;
    csvFile.close();
    
    
    return(numLines);
}

char **readData()
{
    char **csvContent = NULL;
    int csvRows = countRows();
    int i = 0;
    
    ifstream csvFile;
    
    csvContent = new char*[csvRows + 1];
    
    csvFile.open("patients.csv");
    while(csvFile.good()) {
        string line;
        getline(csvFile, line, ',');

        csvContent[i] = new char[line.length() + 1];
        
        for(int j = 0; j < line.length(); j++)
        {
            csvContent[i][j] = line[j];
        }
        i++;
    }
    csvFile.close();
    
    return(csvContent);
}

char *EventType()
{
    char **eventData = readData();

    return(eventData[5]);
}
