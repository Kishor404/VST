# Generated by Django 5.1.4 on 2025-01-26 04:53

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('service', '0004_rename_compliant_service_complaint'),
    ]

    operations = [
        migrations.AddField(
            model_name='service',
            name='available',
            field=models.JSONField(default={'from': '09/09/2024', 'to': '09/10/2024'}),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='service',
            name='complaint',
            field=models.CharField(choices=[('IND', 'India'), ('USA', 'United States'), ('AUS', 'Australia')], default='Regular Service', max_length=255),
        ),
    ]
