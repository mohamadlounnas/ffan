/*
 * Apple System Management Control (SMC) Tool
 * Based on smcFanControl by devnull & Hendrik Holtmann
 * GPL License
 * 
 * Modified for standalone fan speed control helper
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <IOKit/IOKitLib.h>
#include "smc.h"

static io_connect_t g_conn = 0;

#pragma mark - Helper Functions

UInt32 _strtoul(char *str, int size, int base)
{
    UInt32 total = 0;
    int i;

    for (i = 0; i < size; i++)
    {
        if (base == 16)
            total += str[i] << (size - 1 - i) * 8;
        else
           total += ((unsigned char) (str[i]) << (size - 1 - i) * 8);
    }
    return total;
}

void _ultostr(char *str, UInt32 val)
{
    str[0] = '\0';
    sprintf(str, "%c%c%c%c",
            (unsigned int) val >> 24,
            (unsigned int) val >> 16,
            (unsigned int) val >> 8,
            (unsigned int) val);
}

float _strtof(unsigned char *str, int size, int e)
{
    float total = 0;
    int i;
    
    for (i = 0; i < size; i++)
    {
        if (i == (size - 1))
            total += (str[i] & 0xff) >> e;
        else
            total += str[i] << (size - 1 - i) * (8 - e);
    }
    
    total += (str[size-1] & 0x03) * 0.25;
    return total;
}

float getFloatFromVal(SMCVal_t val)
{
    float fval = -1.0f;

    if (val.dataSize > 0)
    {
        if (strcmp(val.dataType, DATATYPE_FLT) == 0 && val.dataSize == 4) {
             memcpy(&fval, val.bytes, sizeof(float));
        }
        else if (strcmp(val.dataType, DATATYPE_FPE2) == 0 && val.dataSize == 2) {
             fval = _strtof(val.bytes, val.dataSize, 2);
        }
        else if (strcmp(val.dataType, DATATYPE_UINT16) == 0 && val.dataSize == 2) {
             fval = (float)_strtoul((char *)val.bytes, val.dataSize, 10);
        }
        else if (strcmp(val.dataType, DATATYPE_UINT8) == 0 && val.dataSize == 1) {
             fval = (float)_strtoul((char *)val.bytes, val.dataSize, 10);
        }
    }
    return fval;
}

#pragma mark - SMC Functions

kern_return_t SMCCall(int index, SMCKeyData_t *inputStructure, SMCKeyData_t *outputStructure, io_connect_t conn)
{
    size_t structureInputSize = sizeof(SMCKeyData_t);
    size_t structureOutputSize = sizeof(SMCKeyData_t);
    
    return IOConnectCallStructMethod(conn, index, inputStructure, structureInputSize, outputStructure, &structureOutputSize);
}

kern_return_t SMCOpen(io_connect_t *conn)
{
    kern_return_t result;
    mach_port_t   masterPort;
    io_iterator_t iterator;
    io_object_t   device;
    
    IOMasterPort(MACH_PORT_NULL, &masterPort);
    
    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: IOServiceGetMatchingServices() = %08x\n", result);
        return result;
    }
    
    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0)
    {
        fprintf(stderr, "Error: no SMC found\n");
        return kIOReturnNotFound;
    }
    
    result = IOServiceOpen(device, mach_task_self(), 0, conn);
    IOObjectRelease(device);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: IOServiceOpen() = %08x\n", result);
        return result;
    }
    
    return kIOReturnSuccess;
}

kern_return_t SMCClose(io_connect_t conn)
{
    return IOServiceClose(conn);
}

kern_return_t SMCGetKeyInfo(UInt32 key, SMCKeyData_keyInfo_t *keyInfo, io_connect_t conn)
{
    SMCKeyData_t inputStructure;
    SMCKeyData_t outputStructure;
    kern_return_t result;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    
    inputStructure.key = key;
    inputStructure.data8 = SMC_CMD_READ_KEYINFO;
    
    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure, conn);
    if (result == kIOReturnSuccess)
    {
        *keyInfo = outputStructure.keyInfo;
    }
    
    return result;
}

kern_return_t SMCReadKey(UInt32Char_t key, SMCVal_t *val, io_connect_t conn)
{
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    memset(val, 0, sizeof(SMCVal_t));
    
    inputStructure.key = _strtoul(key, 4, 16);
    sprintf(val->key, "%s", key);
    
    result = SMCGetKeyInfo(inputStructure.key, &outputStructure.keyInfo, conn);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    val->dataSize = outputStructure.keyInfo.dataSize;
    _ultostr(val->dataType, outputStructure.keyInfo.dataType);
    inputStructure.keyInfo.dataSize = val->dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;
    
    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure, conn);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    
    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));
    
    return kIOReturnSuccess;
}

kern_return_t SMCWriteKey(SMCVal_t writeVal, io_connect_t conn)
{
    kern_return_t result;
    SMCKeyData_t  inputStructure;
    SMCKeyData_t  outputStructure;
    SMCVal_t      readVal;
    
    // First read to get dataSize
    result = SMCReadKey(writeVal.key, &readVal, conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: SMCReadKey failed for %s: %08x\n", writeVal.key, result);
        return result;
    }
    
    if (readVal.dataSize != writeVal.dataSize)
    {
        fprintf(stderr, "Error: dataSize mismatch (read=%u, write=%u)\n", readVal.dataSize, writeVal.dataSize);
        return kIOReturnError;
    }
    
    memset(&inputStructure, 0, sizeof(SMCKeyData_t));
    memset(&outputStructure, 0, sizeof(SMCKeyData_t));
    
    inputStructure.key = _strtoul(writeVal.key, 4, 16);
    inputStructure.data8 = SMC_CMD_WRITE_BYTES;
    inputStructure.keyInfo.dataSize = writeVal.dataSize;
    memcpy(inputStructure.bytes, writeVal.bytes, sizeof(writeVal.bytes));
    
    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure, conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: SMCCall write failed: %08x\n", result);
        return result;
    }
    
    return kIOReturnSuccess;
}

#pragma mark - Fan Control Functions

int getFanCount(io_connect_t conn)
{
    SMCVal_t val;
    kern_return_t result = SMCReadKey("FNum", &val, conn);
    if (result != kIOReturnSuccess)
        return 0;
    return (int)_strtoul((char *)val.bytes, val.dataSize, 10);
}

float getFanSpeed(int fanNum, io_connect_t conn)
{
    SMCVal_t val;
    char key[5];
    sprintf(key, "F%dAc", fanNum);
    
    kern_return_t result = SMCReadKey(key, &val, conn);
    if (result != kIOReturnSuccess)
        return -1;
    
    return getFloatFromVal(val);
}

float getFanMinSpeed(int fanNum, io_connect_t conn)
{
    SMCVal_t val;
    char key[5];
    sprintf(key, "F%dMn", fanNum);
    
    kern_return_t result = SMCReadKey(key, &val, conn);
    if (result != kIOReturnSuccess)
        return -1;
    
    return getFloatFromVal(val);
}

kern_return_t setFanMode(int fanNum, int mode, io_connect_t conn)
{
    SMCVal_t val;
    char key[5];
    sprintf(key, "F%dMd", fanNum);
    
    kern_return_t result = SMCReadKey(key, &val, conn);
    if (result != kIOReturnSuccess)
    {
        // F{n}Md might not exist on some systems
        return kIOReturnSuccess; // Not an error, just skip
    }
    
    if (val.dataSize == 1)
    {
        val.bytes[0] = (UInt8)mode;
        sprintf(val.key, "%s", key);
        result = SMCWriteKey(val, conn);
    }
    
    return result;
}

kern_return_t setFanSpeed(int fanNum, int speed, io_connect_t conn)
{
    SMCVal_t val;
    char key[5];
    
    // First, set fan mode to forced (1)
    setFanMode(fanNum, 1, conn);
    
    // Then set target speed using F{n}Tg
    sprintf(key, "F%dTg", fanNum);
    
    kern_return_t result = SMCReadKey(key, &val, conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: Cannot read %s\n", key);
        return result;
    }
    
    // Encode based on data type
    if (strcmp(val.dataType, DATATYPE_FLT) == 0 && val.dataSize == 4)
    {
        // float type (Apple Silicon)
        float fspeed = (float)speed;
        memcpy(val.bytes, &fspeed, sizeof(float));
    }
    else if (strcmp(val.dataType, DATATYPE_FPE2) == 0 && val.dataSize == 2)
    {
        // fpe2 encoding (Intel): value << 2, big endian
        UInt16 encoded = (UInt16)(speed << 2);
        val.bytes[0] = (encoded >> 8) & 0xFF;
        val.bytes[1] = encoded & 0xFF;
    }
    else
    {
        fprintf(stderr, "Error: Unknown type %s for %s\n", val.dataType, key);
        return kIOReturnError;
    }
    
    sprintf(val.key, "%s", key);
    
    result = SMCWriteKey(val, conn);
    return result;
}

kern_return_t setFanAuto(int fanNum, io_connect_t conn)
{
    // Set fan mode back to automatic (0)
    return setFanMode(fanNum, 0, conn);
}

void printFanInfo(io_connect_t conn)
{
    int numFans = getFanCount(conn);
    printf("Total fans: %d\n", numFans);
    
    for (int i = 0; i < numFans; i++)
    {
        SMCVal_t val;
        char key[5];
        
        printf("\nFan #%d:\n", i);
        
        // Current speed
        printf("  Current speed: %.0f RPM\n", getFanSpeed(i, conn));
        
        // Min speed
        sprintf(key, "F%dMn", i);
        if (SMCReadKey(key, &val, conn) == kIOReturnSuccess)
        {
            printf("  Min speed: %.0f RPM (type: %s)\n", getFloatFromVal(val), val.dataType);
        }
        
        // Max speed
        sprintf(key, "F%dMx", i);
        if (SMCReadKey(key, &val, conn) == kIOReturnSuccess)
        {
            printf("  Max speed: %.0f RPM\n", getFloatFromVal(val));
        }
        
        // Target speed
        sprintf(key, "F%dTg", i);
        if (SMCReadKey(key, &val, conn) == kIOReturnSuccess)
        {
            printf("  Target speed: %.0f RPM\n", getFloatFromVal(val));
        }
    }
}

void readKey(const char *keyName, io_connect_t conn)
{
    SMCVal_t val;
    char key[5];
    strncpy(key, keyName, 4);
    key[4] = '\0';
    
    kern_return_t result = SMCReadKey(key, &val, conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: Cannot read key %s: %08x\n", key, result);
        return;
    }
    
    printf("Key: %s\n", key);
    printf("Type: %s\n", val.dataType);
    printf("Size: %u\n", val.dataSize);
    printf("Value: %.2f\n", getFloatFromVal(val));
    
    printf("Bytes: ");
    for (UInt32 i = 0; i < val.dataSize; i++)
    {
        printf("%02x ", (unsigned char)val.bytes[i]);
    }
    printf("\n");
}

void writeKeyHex(const char *keyName, const char *hexValue, io_connect_t conn)
{
    SMCVal_t val;
    char key[5];
    strncpy(key, keyName, 4);
    key[4] = '\0';
    
    // First read to get type and size
    kern_return_t result = SMCReadKey(key, &val, conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: Cannot read key %s: %08x\n", key, result);
        return;
    }
    
    // Parse hex value
    size_t hexLen = strlen(hexValue);
    for (size_t i = 0; i < hexLen / 2 && i < val.dataSize; i++)
    {
        char c[3] = { hexValue[i * 2], hexValue[i * 2 + 1], '\0' };
        val.bytes[i] = (unsigned char)strtol(c, NULL, 16);
    }
    
    sprintf(val.key, "%s", key);
    
    result = SMCWriteKey(val, conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: Write failed: %08x\n", result);
    }
    else
    {
        printf("Success: Wrote to %s\n", key);
        // Verify
        SMCVal_t verify;
        SMCReadKey(key, &verify, conn);
        printf("New value: %.2f\n", getFloatFromVal(verify));
    }
}

void usage(const char *prog)
{
    printf("SMC Fan Control Helper\n");
    printf("Usage:\n");
    printf("  %s info                     - Show fan information\n", prog);
    printf("  %s read <KEY>               - Read SMC key\n", prog);
    printf("  %s set <FAN#> <RPM>         - Set fan target speed (forced mode)\n", prog);
    printf("  %s auto <FAN#>              - Set fan back to automatic mode\n", prog);
    printf("  %s write <KEY> <HEXVALUE>   - Write raw hex to key\n", prog);
    printf("\n");
    printf("Examples:\n");
    printf("  %s set 0 3500               - Set fan 0 to 3500 RPM\n", prog);
    printf("  %s auto 0                   - Set fan 0 back to automatic\n", prog);
    printf("  %s read F0Tg                - Read fan 0 target speed\n", prog);
}

int main(int argc, char *argv[])
{
    kern_return_t result;
    
    if (argc < 2)
    {
        usage(argv[0]);
        return 1;
    }
    
    result = SMCOpen(&g_conn);
    if (result != kIOReturnSuccess)
    {
        fprintf(stderr, "Error: Cannot open SMC connection\n");
        return 1;
    }
    
    const char *cmd = argv[1];
    
    if (strcmp(cmd, "info") == 0)
    {
        printFanInfo(g_conn);
    }
    else if (strcmp(cmd, "read") == 0)
    {
        if (argc < 3)
        {
            fprintf(stderr, "Error: specify key to read\n");
            SMCClose(g_conn);
            return 1;
        }
        readKey(argv[2], g_conn);
    }
    else if (strcmp(cmd, "set") == 0)
    {
        if (argc < 4)
        {
            fprintf(stderr, "Error: specify fan number and speed\n");
            fprintf(stderr, "Usage: %s set <FAN#> <RPM>\n", argv[0]);
            SMCClose(g_conn);
            return 1;
        }
        int fanNum = atoi(argv[2]);
        int speed = atoi(argv[3]);
        
        printf("Setting fan %d to %d RPM (forced mode)...\n", fanNum, speed);
        result = setFanSpeed(fanNum, speed, g_conn);
        if (result == kIOReturnSuccess)
        {
            printf("Success!\n");
            // Verify
            float current = getFanSpeed(fanNum, g_conn);
            SMCVal_t val;
            char key[5];
            sprintf(key, "F%dTg", fanNum);
            SMCReadKey(key, &val, g_conn);
            printf("Target speed: %.0f RPM\n", getFloatFromVal(val));
            printf("Current speed: %.0f RPM\n", current);
        }
        else
        {
            fprintf(stderr, "Error: Failed to set fan speed: %08x\n", result);
            if (result == 0xe00002c1) // kIOReturnNotPrivileged
            {
                fprintf(stderr, "Hint: Run with sudo for privileged operations\n");
            }
            SMCClose(g_conn);
            return 1;
        }
    }
    else if (strcmp(cmd, "auto") == 0)
    {
        if (argc < 3)
        {
            fprintf(stderr, "Error: specify fan number\n");
            fprintf(stderr, "Usage: %s auto <FAN#>\n", argv[0]);
            SMCClose(g_conn);
            return 1;
        }
        int fanNum = atoi(argv[2]);
        
        printf("Setting fan %d to automatic mode...\n", fanNum);
        result = setFanAuto(fanNum, g_conn);
        if (result == kIOReturnSuccess)
        {
            printf("Success! Fan %d is now in automatic mode.\n", fanNum);
        }
        else
        {
            fprintf(stderr, "Error: Failed to set fan mode: %08x\n", result);
            SMCClose(g_conn);
            return 1;
        }
    }
    else if (strcmp(cmd, "write") == 0)
    {
        if (argc < 4)
        {
            fprintf(stderr, "Error: specify key and hex value\n");
            fprintf(stderr, "Usage: %s write <KEY> <HEXVALUE>\n", argv[0]);
            SMCClose(g_conn);
            return 1;
        }
        writeKeyHex(argv[2], argv[3], g_conn);
    }
    else
    {
        fprintf(stderr, "Unknown command: %s\n", cmd);
        usage(argv[0]);
        SMCClose(g_conn);
        return 1;
    }
    
    SMCClose(g_conn);
    return 0;
}
