# Generated by Django 2.2.10 on 2020-05-13 01:59

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('reo', '0058_auto_20200512_1609'),
    ]

    operations = [
        migrations.AddField(
            model_name='profilemodel',
            name='pyjulia_activate_include_seconds',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='profilemodel',
            name='pyjulia_reopt_seconds',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
