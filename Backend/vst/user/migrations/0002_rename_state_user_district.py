# Generated by Django 5.1.4 on 2025-02-03 09:59

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('user', '0001_initial'),
    ]

    operations = [
        migrations.RenameField(
            model_name='user',
            old_name='state',
            new_name='district',
        ),
    ]
