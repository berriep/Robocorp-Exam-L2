*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.FileSystem
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             SeleniumLibrary

Suite Setup         Manage Directories
Suite Teardown      Cleanup


*** Variables ***
${url_orderfile}        https://robotsparebinindustries.com/orders.csv
${url_order_page}       https://robotsparebinindustries.com/#/robot-order
${outfolder}            ${CURDIR}${/}output
${datafolder}           ${outfolder}${/}datafolder
${screenshotsfolder}    ${datafolder}${/}screenshots
${receiptsfolder}       ${datafolder}${/}receipts
${downloadsfolder}      ${datafolder}${/}downloads
${archivesfolder}       ${datafolder}${/}archives


*** Tasks ***
Order Robots
    Download orders file
    Open Orderpage
    ${orders}=    Read table from CSV    ${downloadsfolder}${/}orders.csv    ${TRUE}
    FOR    ${order}    IN    @{orders}
        Log    Working on ordernumber ${order}[Order number]    console=${TRUE}    
        Close the annoying modal
        Fill orderform    ${order}
        Wait Until Keyword Succeeds    15 times    1s    Preview order
        Wait Until Keyword Succeeds    15 times    1s    Confirm order
        Get info from order    ${order}
        Wait Until Keyword Succeeds    15 times    1s    Place another order
    END
    Archive Folder With Zip    ${receiptsfolder}    ${outfolder}${/}receipts.zip    include=*.pdf


*** Keywords ***
Manage Directories
    Create Directory    ${datafolder}
    Create Directory    ${screenshotsfolder}
    Create Directory    ${receiptsfolder}
    Create Directory    ${downloadsfolder}
    Empty Directory    ${screenshotsfolder}
    Empty Directory    ${receiptsfolder}
    Empty Directory    ${downloadsfolder}

Open Orderpage
    Open Available Browser    ${url_order_page}    headless=${True}

Download orders file
    [Documentation]    Download the orders file
    Download    ${url_orderfile}    ${downloadsfolder}    overwrite=${TRUE}

Close the annoying modal
    Wait And Click Button    //button[@class="btn btn-dark"]
    RPA.Browser.Selenium.Wait Until Element Is Not Visible    //button[@class="btn btn-dark"]    10

Fill orderform
    [Arguments]    ${order}
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:head    2
    RPA.Browser.Selenium.Wait Until Element Is Enabled    id:head    2
    RPA.Browser.Selenium.Select From List By Value    id:head    ${order}[Head]
    RPA.Browser.Selenium.Click Element    id:id-body-${order}[Body]
    RPA.Browser.Selenium.Input Text    //input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    RPA.Browser.Selenium.Input Text    id:address    ${order}[Address]

Preview order
    RPA.Browser.Selenium.Wait And Click Button    //button[@class="btn btn-secondary"]
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:robot-preview-image    2

Confirm order
    Mute Run On Failure    Wait Until Element Is Visible
    RPA.Browser.Selenium.Wait And Click Button    id:order
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:order-completion    2

Get info from order
    [Arguments]    ${order}
    ${receipt_pdf}=    Set Variable    ${receiptsfolder}${/}${order}[Order number].pdf
    ${screenshot_jpg}=    Set Variable    ${screenshotsfolder}${/}${order}[Order number].jpg
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:receipt    5
    ${receipt}=    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${receipt_pdf}
    Log    ${receipt_pdf}    console=${TRUE}
    ${screenshot}=    Screenshot    id:robot-preview-image    ${screenshot_jpg}
    ${list_screenshots}=    Create List    ${screenshot}
    Add Files To Pdf    ${list_screenshots}    ${receipt_pdf}    ${TRUE}

Place another order
    RPA.Browser.Selenium.Wait And Click Button    id:order-another
    RPA.Browser.Selenium.Wait Until Element Is Not Visible    id:order-completion    2

Cleanup
    RPA.Browser.Selenium.Close All Browsers
