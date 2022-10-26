*** Settings ***
Documentation   Certificate level II robot.
...             Orders robots from RobotSpareBin Industries inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embes the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
#Library        RPA.Browser.Playwright
Library        RPA.Browser.Selenium
Library        RPA.Excel.Files
Library        RPA.HTTP
Library        RPA.Robocorp.Vault.FileSecrets
Library        RPA.Tables
Library        RPA.PDF
Library        RPA.Archive
Library        RPA.FileSystem
Library        Dialogs

*** Variables***
${EXCEL_FILE_URL}=      https://robotsparebinindustries.com/orders.csv
${EXCEL_DIRECTORY}=     ${CURDIR}${/}DataSets
${PDF_DIRECTORY}=       ${CURDIR}${/}output${/}PDFs
${SCREENSHOT_DIRECTORY}=       ${CURDIR}${/}output${/}Screenshots

*** Tasks ***
Order Robots
    Clear output
    Open the robot order website
    @{orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure    Close the modal 
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit The Order
        Print PDF receipt    ${order}[Order number]   
        ${image_Path}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the PDF receipt    ${image_Path}    ${order}[Order number]
        Navigate to the next order
    END
    Store the receipts in a ZIP file


*** Keywords ***
Clear output    
    Empty Directory    ${PDF_DIRECTORY}
    Empty Directory    ${SCREENSHOT_DIRECTORY}

Open the robot order website
    ${URL}=   RPA.Robocorp.Vault.FileSecrets.Get Secret    URL
    Open Chrome Browser    ${URL}[robotsparebin]    maximized=${TRUE}

Close the modal
    ${Cookie_Selection}=    Get Selection From User    Would you like your privay invaded?    OK    Yep    I guess so...
    Click Button    ${Cookie_Selection}

Get orders
    ${CSV_URL}=   RPA.Robocorp.Vault.FileSecrets.Get Secret    CSV_URL
    RPA.HTTP.Download    ${CSV_URL}[robotsparebin_CsvFile]    ${EXCEL_DIRECTORY}    overwrite=${TRUE}
    ${orders}=    Read table from CSV    ${CURDIR}${/}DataSets${/}orders.csv    header=${TRUE}
    [Return]         ${orders}
    
Fill the form
    [Arguments]    ${Order}
    Log    ${order}[Head] 
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${Order}[Head]  
    Select Radio Button    body    id-body-${Order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
        
Preview the robot
    Click Element    id:preview 

Submit the order
    Click Element    id:order    
    Is Element Visible    id:order-completion    missing_ok=False

Print PDF receipt
    [Arguments]    ${order_Number}
    ${Element_HTML}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${Element_HTML}    ${PDF_DIRECTORY}${/}receipt_${order_Number}.pdf          

Take a screenshot of the robot
    [Arguments]    ${order_Number}
    ${screenshot_Path}=    Set Variable    ${SCREENSHOT_DIRECTORY}${/}screenshot_${order_Number}.png
    Screenshot    id:robot-preview-image    ${screenshot_Path}
    [Return]    ${screenshot_Path}

Embed the robot screenshot to the PDF receipt
    [Arguments]    ${screenshot_Path}    ${order_Number}
    Open Pdf    ${PDF_DIRECTORY}${/}receipt_${order_Number}.pdf
    Add Watermark Image To Pdf    
    ...    ${screenshot_Path}    
    ...    ${PDF_DIRECTORY}${/}receipt_${order_Number}.pdf

Navigate to the next order
    Click Element    id:order-another
    
Store the receipts in a ZIP file
    Archive Folder With Zip    ${PDF_DIRECTORY}    ${PDF_DIRECTORY}.zip
    

        


