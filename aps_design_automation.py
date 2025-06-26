#!/usr/bin/env python3
import os
import json
import time
import requests
import click
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

class APSDesignAutomation:
    def __init__(self):
        self.client_id = os.getenv('APS_CLIENT_ID')
        self.client_secret = os.getenv('APS_CLIENT_SECRET')
        self.bucket_name = os.getenv('APS_BUCKET_NAME')
        self.base_url = "https://developer.api.autodesk.com"
        self.access_token = None
        self.session = requests.Session()
    
    def get_access_token(self):
        if self.access_token:
            return self.access_token
        
        response = self.session.post(
            f"{self.base_url}/authentication/v2/token",
            headers={'Content-Type': 'application/x-www-form-urlencoded'},
            data={
                'grant_type': 'client_credentials',
                'scope': 'data:read data:write bucket:create bucket:read'
            },
            auth=(self.client_id, self.client_secret)
        )
        self.access_token = response.json()['access_token']
        return self.access_token
    
    def ensure_bucket(self):
        token = self.get_access_token()
        
        try:
            self.session.get(
                f"{self.base_url}/oss/v2/buckets/{self.bucket_name}/details",
                headers={'Authorization': f'Bearer {token}'}
            )
        except:
            self.session.post(
                f"{self.base_url}/oss/v2/buckets",
                headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
                json={'bucketKey': self.bucket_name, 'policyKey': 'transient'}
            )
    
    def upload_file(self, file_path):
        self.ensure_bucket()
        token = self.get_access_token()
        file_name = Path(file_path).name
        object_key = f"input/{file_name}"
        
        response = self.session.get(
            f"{self.base_url}/oss/v2/buckets/{self.bucket_name}/objects/{object_key}/signeds3upload",
            headers={'Authorization': f'Bearer {token}'}
        )
        upload_data = response.json()
        
        with open(file_path, 'rb') as f:
            requests.put(upload_data['urls'][0], data=f)
        
        self.session.post(
            f"{self.base_url}/oss/v2/buckets/{self.bucket_name}/objects/{object_key}/signeds3upload",
            headers={'Authorization': f'Bearer {token}'},
            json={'uploadKey': upload_data['uploadKey']}
        )
        
        return object_key
    
    def _read_file(self, file_path):
        with open(Path(__file__).parent / file_path, 'r', encoding='utf-8') as f:
            return f.read()
    
    def _upload_script(self, object_key, content):
        token = self.get_access_token()
        response = self.session.get(
            f"{self.base_url}/oss/v2/buckets/{self.bucket_name}/objects/{object_key}/signeds3upload",
            headers={'Authorization': f'Bearer {token}'}
        )
        upload_data = response.json()
        
        requests.put(upload_data['urls'][0], data=content.encode('utf-8'))
        
        self.session.post(
            f"{self.base_url}/oss/v2/buckets/{self.bucket_name}/objects/{object_key}/signeds3upload",
            headers={'Authorization': f'Bearer {token}'},
            json={'uploadKey': upload_data['uploadKey']}
        )
    
    def create_work_item(self, input_file_key, lisp_file, output_file, activity_id):
        token = self.get_access_token()
        
        lisp_script = self._read_file(f"scripts/{lisp_file}")
        scr_template = self._read_file("scripts/execute_script.scr")
        scr_script = scr_template.replace('{lisp_file}', lisp_file)
        work_item_template = self._read_file("scripts/work_item.json")
        
        work_item = json.loads(work_item_template
            .replace('{bucket_name}', self.bucket_name)
            .replace('{input_file_key}', input_file_key)
            .replace('{lisp_file}', lisp_file)
            .replace('{output_file}', output_file)
            .replace('{activity_id}', activity_id)
        )
        
        self._upload_script(f"scripts/{lisp_file}", lisp_script)
        self._upload_script("scripts/execute_script.scr", scr_script)
        
        response = self.session.post(
            f"{self.base_url}/da/us-east/v3/workitems",
            headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
            json=work_item
        )
        
        return response.json()['id']
    
    def wait_for_completion(self, work_item_id, timeout=300):
        token = self.get_access_token()
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            response = self.session.get(
                f"{self.base_url}/da/us-east/v3/workitems/{work_item_id}",
                headers={'Authorization': f'Bearer {token}'}
            )
            work_item_data = response.json()
            status = work_item_data['status']
            
            if status == 'Succeeded':
                return work_item_data
            elif status in ['Failed', 'Cancelled']:
                raise Exception(f"Work item failed: {status}")
            
            time.sleep(5)
        
        raise TimeoutError(f"Work item timeout: {timeout}s")
    
    def get_download_url(self, object_key, expires_in=3600):
        token = self.get_access_token()
        response = self.session.get(
            f"{self.base_url}/oss/v2/buckets/{self.bucket_name}/objects/{object_key}/signeds3download",
            headers={'Authorization': f'Bearer {token}'},
            params={'minutesExpiration': expires_in // 60}
        )
        return response.json()['signedUrl']

@click.command()
@click.argument('dwg_file', type=click.Path(exists=True, path_type=Path))
@click.option('--lisp', default='modify_title.lsp', help='LISP script file to use')
@click.option('--output', default='result.pdf', help='Output file name')
@click.option('--activity', default='AutoCAD.ModifyTitleBlock+prod', help='Design Automation activity ID')
@click.option('--timeout', default=300, help='Timeout in seconds')
@click.option('--expires', default=3600, help='URL expiration in seconds')
def main(dwg_file, lisp, output, activity, timeout, expires):
    aps = APSDesignAutomation()
    
    click.echo(f"Processing: {dwg_file}")
    click.echo(f"Using LISP: {lisp}")
    click.echo(f"Output: {output}")
    
    input_file_key = aps.upload_file(str(dwg_file))
    work_item_id = aps.create_work_item(input_file_key, lisp, output, activity)
    aps.wait_for_completion(work_item_id, timeout)
    download_url = aps.get_download_url(f"output/{output}", expires)
    
    click.echo(f"Download URL: {download_url}")

if __name__ == '__main__':
    main() 