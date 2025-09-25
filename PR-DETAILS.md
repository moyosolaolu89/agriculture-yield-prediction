# Yield Oracle Smart Contract

## Summary

Advanced smart contract system for agricultural yield prediction and parametric crop insurance using satellite data and weather conditions. The system provides automated, data-driven insurance coverage that protects farmers against crop yield losses through real-time environmental monitoring and AI-powered yield forecasting.

## Smart Contract Features

### Core Functionality
- **Satellite Data Integration**: Real-time crop monitoring using NDVI, EVI, and soil moisture data
- **Weather Data Processing**: Comprehensive weather analysis including temperature, precipitation, and humidity
- **Yield Prediction Models**: AI-driven forecasting with confidence levels and risk factor analysis
- **Parametric Insurance**: Automatic payout triggers based on environmental conditions
- **Multi-Crop Support**: Coverage for 6 major crop types (Wheat, Corn, Rice, Soybeans, Cotton, Barley)

### Key Components

#### Oracle System
- Authorized oracle management with role-based data submission
- Multi-source data validation from weather and satellite providers
- Real-time data verification and timestamp tracking
- Oracle performance monitoring and update statistics

#### Insurance Policy Management
- Comprehensive policy creation with location-specific parameters
- Dynamic premium calculation based on risk assessment
- Policy lifecycle management (Active, Expired, Claimed, Cancelled)
- Coverage amount validation with minimum and maximum limits

#### Environmental Data Processing
- Weather data storage with temperature, precipitation, humidity, and wind metrics
- Satellite data analysis including vegetation indices and soil conditions
- Geographic coordinate-based data organization
- Historical weather pattern analysis and trend tracking

#### Automated Payout System
- Threshold-based payout triggers using environmental data
- Yield loss percentage calculations with evidence documentation
- Immediate fund transfers to affected farmers
- Comprehensive payout audit trails

### Technical Implementation
- **Lines of Code**: 559 lines
- **Error Handling**: 10 comprehensive error codes
- **Data Maps**: 7 specialized data structures
- **Public Functions**: 6 core operations
- **Read-Only Functions**: 10 query operations

### Advanced Features

#### Risk Assessment
- Geographic risk multiplier calculations
- Crop-specific yield expectations based on location
- Historical yield data integration for improved accuracy
- Multi-factor risk scoring including drought, flood, frost, and pest risks

#### Premium Calculation
- Base rate of 3% with dynamic adjustments
- Area-based multipliers for planted acreage
- Location-specific risk factors
- Crop type considerations for premium pricing

#### Yield Prediction Integration
- Confidence level tracking for prediction accuracy
- Risk factor analysis with up to 10 identified factors
- Multiple prediction model support
- Automatic payout triggering based on predicted yields

## Data Sources & Integration

### Satellite Data Metrics
- **NDVI (Normalized Difference Vegetation Index)**: Crop health monitoring
- **EVI (Enhanced Vegetation Index)**: Advanced vegetation analysis
- **Soil Moisture**: Ground condition assessment
- **Land Surface Temperature**: Heat stress evaluation
- **Cloud Cover**: Data quality and accuracy metrics

### Weather Data Parameters
- **Temperature Range**: Daily minimum and maximum temperatures
- **Precipitation**: Rainfall amounts and distribution patterns
- **Humidity Levels**: Atmospheric moisture monitoring
- **Wind Speed**: Storm tracking and weather pattern analysis

### Agricultural Intelligence
- **Expected Yield Calculations**: Crop-specific productivity estimates
- **Minimum Yield Thresholds**: Payout trigger points
- **Historical Performance**: Past yield data for trend analysis
- **Risk Factor Identification**: Environmental threat assessment

## Use Cases & Applications

### Crop Insurance Coverage
- Drought protection triggered by precipitation deficits
- Frost damage coverage based on temperature thresholds
- Flood insurance activated by excessive rainfall
- Heat stress protection using temperature monitoring

### Precision Agriculture Support
- Real-time crop health monitoring for farmers
- Early warning systems for environmental threats
- Seasonal risk assessment and mitigation planning
- Data-driven decision support for planting and harvesting

### Financial Risk Management
- Agricultural lending risk assessment
- Crop-backed financial product development
- Commodity market risk hedging
- Supply chain risk mitigation for food companies

## Testing & Validation

The contract successfully compiles with `clarinet check` showing only standard warnings for unchecked data usage. All core functions implement comprehensive validation logic and proper error handling.

## Economic Model

### Fee Structure
- 2% platform fee on premium payments
- Risk-based premium calculations
- Geographic and crop-specific adjustments
- Coverage limits from 1 STX to 100,000 STX

### Payout Mechanisms
- Automatic trigger-based payouts
- Yield loss percentage calculations
- Evidence-based claim documentation
- Platform reserve management for sustainability

## Impact & Innovation

This implementation revolutionizes agricultural insurance by:
1. Providing immediate, data-driven claim processing
2. Eliminating subjective claim assessments
3. Reducing fraud through objective environmental triggers
4. Supporting climate-resilient agricultural practices
5. Enabling precision agriculture adoption

The system bridges the gap between traditional agriculture and modern technology, offering farmers reliable protection against climate-related risks while promoting sustainable farming practices.