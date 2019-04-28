//
//  readingCSV.h
//  MUSC-Anesthesia
//
//  Created by Nicolas Threatt on 6/25/18.
//  Copyright © 2018 Riggs Lab. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

// Count number of rows in CSV file
int countRows();
    
// Get data from CSV file
char **readData();
    
// Get event data
char *EventType();
    
#ifdef __cplusplus
}
#endif
