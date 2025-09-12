# Policies API Guide

This guide explains the new comprehensive policies management system that has been added to the FinBot AI Agent application.

## Overview

The policies system allows you to manage expense policies with detailed configurations including limits, approval workflows, reimbursement methods, and compliance requirements. The system supports the complete dataset structure provided and includes both database storage and file upload capabilities.

## Policy Model

The `Policy` record includes the following fields:

### Core Fields
- `Id` (string): Unique policy identifier
- `Category` (string): Policy category (e.g., "Travel", "Meals", "Lodging")
- `Limit` (decimal?): Spending limit amount
- `Currency` (string): Currency code (default: "USD")
- `PerPerson` (bool): Whether limit applies per person
- `PerDay` (bool): Whether limit applies per day
- `ReceiptsRequiredOver` (decimal): Amount threshold requiring receipts

### Approval & Workflow
- `ApprovalLevel` (string[]): Required approval levels (e.g., ["manager", "finance"])
- `ReimbursementMethod` (string[]): Allowed reimbursement methods (e.g., ["Payroll", "BankTransfer"])
- `RequiresProjectCode` (bool): Whether project code is required
- `ReceiptRetentionDays` (int): Days to retain receipts (default: 365)

### Compliance & Validation
- `ConfidenceThresholdForOCR` (decimal): OCR confidence threshold (0.0-1.0)
- `CurrencyConversionAllowed` (bool): Whether currency conversion is allowed
- `TaxIncluded` (bool?): Whether tax is included in amounts

### Policy Details
- `Exceptions` (string?): Policy exceptions and special rules
- `EffectiveFrom` (string): Policy effective start date
- `EffectiveTo` (string?): Policy effective end date (null for ongoing)
- `Notes` (string?): Additional policy notes
- `LastUpdatedAt` (DateTime): Last update timestamp
- `LastUpdatedBy` (string): User who last updated the policy

### Specialized Fields
- `MileageRate` (decimal?): Rate per mile for mileage policies
- `Unit` (string?): Unit of measurement (e.g., "mile", "km")
- `MaxItems` (int?): Maximum number of items allowed

## API Endpoints

### 1. Get All Policies
```
GET /api/policies
```
Returns all policies ordered by category and ID.

### 2. Get Policy by ID
```
GET /api/policies/{id}
```
Returns a specific policy by its ID.

### 3. Create New Policy
```
POST /api/policies
Content-Type: application/json

{
  "id": "policy-example-001",
  "category": "Travel",
  "limit": 1000,
  "currency": "USD",
  "per_person": false,
  "per_day": false,
  "receipts_required_over": 0,
  "approval_level": ["manager"],
  "reimbursement_method": ["Payroll", "BankTransfer"],
  "exceptions": "International travel requires pre-approval",
  "effective_from": "2025-01-01",
  "effective_to": null,
  "notes": "Use corporate travel booking when possible",
  "last_updated_by": "admin@company.com",
  "requires_project_code": false,
  "receipt_retention_days": 1095,
  "confidence_threshold_for_OCR": 0.6,
  "currency_conversion_allowed": false
}
```

### 4. Update Policy
```
PUT /api/policies/{id}
Content-Type: application/json

{
  // Same structure as create, but updates existing policy
}
```

### 5. Delete Policy
```
DELETE /api/policies/{id}
```

### 6. Upload Policies from JSON File
```
POST /api/policies/upload
Content-Type: multipart/form-data

file: [JSON file containing array of policies]
```

### 7. Bulk Create Policies
```
POST /api/policies/bulk
Content-Type: application/json

[
  {
    // Policy 1
  },
  {
    // Policy 2
  }
]
```

## Database Schema

The policies are stored in a PostgreSQL table with the following structure:

```sql
CREATE TABLE policies (
    id VARCHAR(50) PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    limit_amount DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'USD',
    per_person BOOLEAN DEFAULT FALSE,
    per_day BOOLEAN DEFAULT FALSE,
    receipts_required_over DECIMAL(10,2) DEFAULT 0,
    approval_level TEXT[],
    reimbursement_method TEXT[],
    exceptions TEXT,
    effective_from DATE NOT NULL,
    effective_to DATE,
    notes TEXT,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated_by VARCHAR(255),
    requires_project_code BOOLEAN DEFAULT FALSE,
    receipt_retention_days INTEGER DEFAULT 365,
    confidence_threshold_for_ocr DECIMAL(3,2) DEFAULT 0.5,
    currency_conversion_allowed BOOLEAN DEFAULT FALSE,
    mileage_rate DECIMAL(5,2),
    unit VARCHAR(20),
    tax_included BOOLEAN,
    max_items INTEGER
);
```

## Sample Data

The application comes pre-seeded with 12 comprehensive policies covering:

1. **Travel** - Airfare, hotels, ground transportation
2. **Meals** - Business meals and client entertainment
3. **Lodging** - Hotel accommodations
4. **Office Supplies** - Stationery and equipment
5. **Mileage** - Vehicle mileage reimbursement
6. **Transportation** - Taxi, rideshare, public transit
7. **Internet** - Home internet stipends
8. **Client Entertainment** - Client meals and events
9. **Per Diem** - Daily allowance for travel
10. **Petty Cash** - Small unplanned expenses
11. **Parking** - Parking fees and permits
12. **Telephone** - Business phone expenses

## Testing

### Using the Test Files

1. **HTTP Test File**: Use `test-policies.http` with your IDE's HTTP client
2. **HTML Upload Form**: Open `policy-upload-test.html` in a browser
3. **Sample JSON**: Use `sample-policies.json` for testing uploads

### Manual Testing Steps

1. Start the application: `dotnet run`
2. Open Swagger UI: `https://localhost:7000/swagger`
3. Test the endpoints using the interactive documentation
4. Use the HTML form to test file uploads
5. Verify data persistence by restarting the application

## File Upload Format

The JSON file should contain an array of policy objects matching the Policy model structure:

```json
[
  {
    "id": "policy-travel-001",
    "category": "Travel",
    "limit": 1000,
    "currency": "USD",
    "per_person": false,
    "per_day": false,
    "receipts_required_over": 0,
    "approval_level": ["manager"],
    "reimbursement_method": ["Payroll", "BankTransfer"],
    "exceptions": "International travel subject to separate allowance",
    "effective_from": "2025-01-01",
    "effective_to": null,
    "notes": "Use lowest reasonable airfare",
    "last_updated_at": "2025-09-11T12:00:00Z",
    "last_updated_by": "finance.policy@company.com",
    "requires_project_code": false,
    "receipt_retention_days": 1095,
    "confidence_threshold_for_OCR": 0.6,
    "currency_conversion_allowed": false
  }
]
```

## Error Handling

The API includes comprehensive error handling:

- **400 Bad Request**: Invalid JSON format, missing required fields
- **404 Not Found**: Policy not found for GET/PUT/DELETE operations
- **500 Internal Server Error**: Database or server errors

## Validation

- File uploads must be JSON format
- Required fields are validated
- Date formats must be valid (YYYY-MM-DD)
- Array fields are properly handled
- Null values are supported for optional fields

## Integration Notes

- The policies system integrates with the existing expense management system
- Database seeding happens automatically on application startup
- All endpoints are RESTful and follow consistent patterns
- Swagger documentation is automatically generated
- CORS is configured for web client integration

## Security Considerations

- File uploads are validated for JSON format only
- SQL injection protection through parameterized queries
- Input validation on all endpoints
- Proper error handling without exposing sensitive information

## Future Enhancements

Potential future improvements could include:

- Policy versioning and history tracking
- Advanced approval workflows
- Integration with external approval systems
- Policy compliance reporting
- Automated policy updates based on business rules
- Multi-currency support with real-time conversion rates
