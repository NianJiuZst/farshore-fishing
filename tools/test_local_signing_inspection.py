"""Public APK inspection regressions only: never reads a key or invokes signing."""
from pathlib import Path
import copy
import json
import tempfile
import unittest
from unittest import mock
import zipfile

import sign_ocean_apk_locally as local


class LocalSigningInspectionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='farshore-local-inspection-test-')
        self.addCleanup(self.temp.cleanup)
        self.apk=Path(self.temp.name)/'fixture-UNSIGNED-INTERNAL.apk'
        self.addCleanup(mock.patch.stopall)
        mock.patch.object(local.subprocess,'run',side_effect=AssertionError('External commands forbidden')).start()
        mock.patch.object(local.getpass,'getpass',side_effect=AssertionError('Password entry forbidden')).start()

    def fixture(self, version='1.4.1', code=9):
        diversity=version in {'1.4.0','1.4.1'}
        count=110 if diversity else 74
        parts='abcdefgh' if diversity else 'abcdef'
        ordinary=[{'species_id':f'ordinary_{index}'} for index in range(count)]
        payload={f'assets/data/fish_{part}.json':ordinary[index::len(parts)] for index,part in enumerate(parts)}
        if diversity:
            payload['assets/data/fish_whale.json']=[{'species_id':'blue_whale','animal_kind':'mammal',
                'fishing_enabled':False,'encounter_type':'fantasy_challenge'}]
        payload['assets/data/world.json']={
            'regions':[{}]*(10 if diversity else 9), 'spots':[{}]*(21 if diversity else 18),
            'gear':[{}]*(6 if diversity else 5), 'baits':[{}]*12}
        payload['assets/data/android_build_identity.json']={
            'android_package_name':local.PACKAGE,'application_version':version,'android_version_code':code}
        return payload

    def inspect(self, payload, version='1.4.1', code=9, *, extra_badging='', permission='android.permission.VIBRATE', extra_member=None):
        with zipfile.ZipFile(self.apk,'w') as archive:
            archive.writestr('lib/arm64-v8a/libfixture.so',b'INERT TEST BYTES; NEVER EXECUTED')
            for name,value in payload.items(): archive.writestr(name,json.dumps(value))
            if extra_member: archive.writestr(extra_member,b'INERT TEST BYTES')
        before=local.sha256(self.apk)
        badge=(f"package: name='{local.PACKAGE}' versionCode='{code}' versionName='{version}'\n"
               f"application-label:'{local.LABEL}'\nsdkVersion:'29'\ntargetSdkVersion:'36'\n"+extra_badging)
        def inert_run(args, **kwargs):
            executable=Path(args[0]).name
            if executable=='aapt' and args[1:3]==['dump','badging']: return badge
            if executable=='aapt' and args[1:3]==['dump','permissions']: return f"uses-permission: name='{permission}'\n"
            if executable=='zipalign' and args[1:]==['-c','-P','16','4',self.apk]: return 'Verification successful\n'
            self.fail('Unexpected executable/action in pure inspection test: '+str(args))
        with mock.patch.object(local,'run',side_effect=inert_run):
            result=local.inspect_apk(self.apk,Path('/inert/build-tools'))
        self.assertEqual(local.sha256(self.apk),before)
        return result

    def test_accepts_legacy_74_fish_and_diversity_110_fish_plus_whale(self):
        for version,code in [('1.3.0',7),('1.4.0',8),('1.4.1',9)]:
            with self.subTest(version=version):
                result=self.inspect(self.fixture(version,code),version,code)
                self.assertEqual((result['application_version'],result['android_version_code']),(version,code))

    def test_accepts_actual_frozen_diversity_catalog(self):
        root=Path(__file__).resolve().parent.parent/'game/data'
        payload=self.fixture()
        for name in payload: payload[name]=json.loads((root/Path(name).name).read_text())
        self.assertEqual(self.inspect(payload)['android_version_code'],9)

    def test_rejects_crossed_or_unreviewed_version_pairs(self):
        for version,code in [('1.3.0',8),('1.4.0',7),('1.4.0',9),('1.4.1',8),('1.5.0',9)]:
            with self.subTest(version=version,code=code), self.assertRaisesRegex(ValueError,'Unreviewed'):
                self.inspect(self.fixture(),version,code)

    def test_rejects_bundled_identity_drift(self):
        for field,value in [('application_version','1.3.0'),('android_version_code',7),('android_package_name','org.farshore.fishing')]:
            payload=self.fixture(); payload['assets/data/android_build_identity.json'][field]=value
            with self.subTest(field=field), self.assertRaisesRegex(ValueError,'Bundled identity'):
                self.inspect(payload)

    def test_requires_all_new_catalog_files(self):
        for part in ['g','h','whale']:
            payload=self.fixture(); del payload[f'assets/data/fish_{part}.json']
            with self.subTest(part=part), self.assertRaises(KeyError): self.inspect(payload)

    def test_rejects_missing_duplicate_or_disabled_ordinary_fish(self):
        for mutation in ['missing','duplicate','disabled']:
            payload=self.fixture(); fish=payload['assets/data/fish_a.json']
            if mutation=='missing': fish.pop()
            elif mutation=='duplicate': fish[-1]=copy.deepcopy(fish[0])
            else: fish[0]['fishing_enabled']=False
            with self.subTest(mutation=mutation), self.assertRaisesRegex(ValueError,'Incomplete ocean catalog'):
                self.inspect(payload)

    def test_blue_whale_must_remain_one_independent_mammal_challenge(self):
        for field,value in [('species_id','other_whale'),('animal_kind','fish'),('fishing_enabled',True),('encounter_type','ordinary_fishing')]:
            payload=self.fixture(); payload['assets/data/fish_whale.json'][0][field]=value
            with self.subTest(field=field), self.assertRaises(ValueError): self.inspect(payload)

    def test_checks_exact_regions_spots_gear_and_baits(self):
        for version,code in [('1.3.0',7),('1.4.0',8),('1.4.1',9)]:
            for field in ['regions','spots','gear','baits']:
                payload=self.fixture(version,code); payload['assets/data/world.json'][field].pop()
                with self.subTest(version=version,field=field), self.assertRaisesRegex(ValueError,'Incomplete ocean catalog'):
                    self.inspect(payload,version,code)

    def test_existing_release_and_credential_member_guards_remain(self):
        for kwargs in [{'extra_badging':'application-debuggable\n'}, {'permission':'android.permission.INTERNET'},
                       {'extra_member':'assets/forbidden.key'}]:
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError): self.inspect(self.fixture(),**kwargs)


if __name__=='__main__': unittest.main(verbosity=2)
