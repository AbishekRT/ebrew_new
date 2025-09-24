const AWS = require('aws-sdk');
const mysql = require('mysql2/promise');

// Order Processing Lambda Function
exports.processOrder = async (event) => {
    console.log('Processing order:', JSON.stringify(event, null, 2));
    
    const connection = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USERNAME,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_DATABASE
    });
    
    try {
        const orderData = JSON.parse(event.body);
        
        // Insert order into database
        const [result] = await connection.execute(
            'INSERT INTO orders (UserID, OrderDate, SubTotal) VALUES (?, NOW(), ?)',
            [orderData.userId, orderData.total]
        );
        
        // Insert order items
        for (const item of orderData.items) {
            await connection.execute(
                'INSERT INTO order_items (OrderID, ItemID, Quantity) VALUES (?, ?, ?)',
                [result.insertId, item.itemId, item.quantity]
            );
        }
        
        // Send notification (using SNS)
        const sns = new AWS.SNS();
        await sns.publish({
            TopicArn: process.env.ORDER_NOTIFICATION_TOPIC,
            Message: `New order placed: Order ID ${result.insertId}`,
            Subject: 'New eBrew Order'
        }).promise();
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                orderId: result.insertId,
                message: 'Order processed successfully'
            })
        };
        
    } catch (error) {
        console.error('Error processing order:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                success: false,
                message: 'Failed to process order'
            })
        };
    } finally {
        await connection.end();
    }
};

// Image Resizing Lambda Function
exports.resizeProductImage = async (event) => {
    const AWS = require('aws-sdk');
    const sharp = require('sharp');
    
    const s3 = new AWS.S3();
    
    for (const record of event.Records) {
        const bucket = record.s3.bucket.name;
        const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
        
        try {
            // Get the uploaded image
            const originalImage = await s3.getObject({
                Bucket: bucket,
                Key: key
            }).promise();
            
            // Resize to multiple sizes
            const sizes = [
                { width: 150, height: 150, suffix: 'thumb' },
                { width: 300, height: 300, suffix: 'medium' },
                { width: 800, height: 600, suffix: 'large' }
            ];
            
            for (const size of sizes) {
                const resizedImage = await sharp(originalImage.Body)
                    .resize(size.width, size.height, { 
                        fit: 'cover',
                        position: 'center'
                    })
                    .jpeg({ quality: 80 })
                    .toBuffer();
                
                // Upload resized image
                const newKey = key.replace(/(\.[^.]+)$/, `_${size.suffix}$1`);
                await s3.putObject({
                    Bucket: bucket,
                    Key: newKey,
                    Body: resizedImage,
                    ContentType: 'image/jpeg'
                }).promise();
            }
            
            console.log(`Successfully processed ${key}`);
            
        } catch (error) {
            console.error(`Error processing ${key}:`, error);
        }
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Images processed successfully' })
    };
};