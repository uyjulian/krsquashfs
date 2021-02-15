#include <stdio.h>
#include <string.h>
#include <windows.h>
#include "ncbind/ncbind.hpp"
#include <map>
#include <vector>

#include <stdio.h>
#include <stdlib.h>
extern "C"
{
#include "squash.h"
}
#include "tp_stub.h"
#include "CharacterSet.h"


class SquashFsStream : public IStream {

public:
	SquashFsStream(int in_vfd)
	{
		ref_count = 1;
		vfd = in_vfd;
	}

	// IUnknown
	HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppvObject)
	{
		if (riid == IID_IUnknown || riid == IID_ISequentialStream || riid == IID_IStream)
		{
			if (ppvObject == NULL)
				return E_POINTER;
			*ppvObject = this;
			AddRef();
			return S_OK;
		}
		else
		{
			*ppvObject = 0;
			return E_NOINTERFACE;
		}
	}

	ULONG STDMETHODCALLTYPE AddRef(void)
	{
		ref_count++;
		return ref_count;
	}
	
	ULONG STDMETHODCALLTYPE Release(void)
	{
		int ret = --ref_count;
		if (ret <= 0) {
			delete this;
			ret = 0;
		}
		return ret;
	}

	// ISequentialStream
	HRESULT STDMETHODCALLTYPE Read(void *pv, ULONG cb, ULONG *pcbRead)
	{
		ssize_t size = squash_read(vfd, pv, cb);
		if (size != -1)
		{
			*pcbRead = size;
			return S_OK;
		}
		
		return S_FALSE;
	}

	HRESULT STDMETHODCALLTYPE Write(const void *pv, ULONG cb, ULONG *pcbWritten)
	{
		return E_NOTIMPL;
	}

	// IStream
	HRESULT STDMETHODCALLTYPE Seek(LARGE_INTEGER dlibMove,	DWORD dwOrigin, ULARGE_INTEGER *plibNewPosition)
	{
		// 先頭にだけ戻せる
		int whence = SQUASH_SEEK_SET;
		switch (dwOrigin)
		{
		case STREAM_SEEK_SET:
			whence = SQUASH_SEEK_SET;
			break;
		case STREAM_SEEK_CUR:
			whence = SQUASH_SEEK_CUR;
			break;
		case STREAM_SEEK_END:
			whence = SQUASH_SEEK_END;
			break;
		}
		off_t pos = squash_lseek(vfd, dlibMove.QuadPart, whence);
		if (plibNewPosition)
		{
			plibNewPosition->QuadPart = pos;
		}
		return S_OK;
	}
	
	HRESULT STDMETHODCALLTYPE SetSize(ULARGE_INTEGER libNewSize)
	{
		return E_NOTIMPL;
	}
	
	HRESULT STDMETHODCALLTYPE CopyTo(IStream *pstm, ULARGE_INTEGER cb, ULARGE_INTEGER *pcbRead, ULARGE_INTEGER *pcbWritten)
	{
		return E_NOTIMPL;
	}

	HRESULT STDMETHODCALLTYPE Commit(DWORD grfCommitFlags)
	{
		return E_NOTIMPL;
	}

	HRESULT STDMETHODCALLTYPE Revert(void)
	{
		return E_NOTIMPL;
	}

	HRESULT STDMETHODCALLTYPE LockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, DWORD dwLockType)
	{
		return E_NOTIMPL;
	}
	
	HRESULT STDMETHODCALLTYPE UnlockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, DWORD dwLockType)
	{
		return E_NOTIMPL;
	}
	
	HRESULT STDMETHODCALLTYPE Stat(STATSTG *pstatstg, DWORD grfStatFlag)
	{
		if (pstatstg)
		{
			ZeroMemory(pstatstg, sizeof(*pstatstg));

#if 0
			// pwcsName
			// this object's storage pointer does not have a name ...
			if(!(grfStatFlag &  STATFLAG_NONAME))
			{
				// anyway returns an empty string
				LPWSTR str = (LPWSTR)CoTaskMemAlloc(sizeof(*str));
				if(str == NULL) return E_OUTOFMEMORY;
				*str = L'\0';
				pstatstg->pwcsName = str;
			}
#endif

			// type
			pstatstg->type = STGTY_STREAM;

			struct stat st;
			squash_fstat(vfd, &st);
			
			// cbSize
			pstatstg->cbSize.QuadPart = st.st_size;
			
			// mtime, ctime, atime unknown

			// grfMode unknown
			pstatstg->grfMode = STGM_DIRECT | STGM_READ | STGM_SHARE_DENY_WRITE ;
			
			// grfLockSuppoted
			pstatstg->grfLocksSupported = 0;
			
			// grfStatBits unknown
		}
		else
		{
			return E_INVALIDARG;
		}
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE Clone(IStream **ppstm)
	{
		return E_NOTIMPL;
	}

protected:
	/**
	 * デストラクタ
	 */
	virtual ~SquashFsStream()
	{
		squash_close(vfd);
	}

private:
	int ref_count;
	int vfd;
};

class SquashFsStorage : public iTVPStorageMedia
{

public:
	SquashFsStorage(sqfs *in_fs)
	{
		ref_count = 1;
		fs = in_fs;
		char buf[(sizeof(void *) * 2) + 1];
		snprintf(buf, (sizeof(void *) * 2) + 1, "%p", this);
		name = ttstr(TJS_W("squashfs")) + buf;
	}

	virtual ~SquashFsStorage()
	{
		// For now, we are going to leak memory
	}

public:
	// -----------------------------------
	// iTVPStorageMedia Intefaces
	// -----------------------------------

	virtual void TJS_INTF_METHOD AddRef()
	{
		ref_count++;
	};

	virtual void TJS_INTF_METHOD Release()
	{
		if (ref_count == 1)
		{
			delete this;
		}
		else
		{
			ref_count--;
		}
	};

	// returns media name like "file", "http" etc.
	virtual void TJS_INTF_METHOD GetName(ttstr &out_name)
	{
		out_name = name;
	}

	//	virtual ttstr TJS_INTF_METHOD IsCaseSensitive() = 0;
	// returns whether this media is case sensitive or not

	// normalize domain name according with the media's rule
	virtual void TJS_INTF_METHOD NormalizeDomainName(ttstr &name)
	{
		// normalize domain name
		// make all characters small
		tjs_char *p = name.Independ();
		while(*p)
		{
			if(*p >= TJS_W('A') && *p <= TJS_W('Z'))
				*p += TJS_W('a') - TJS_W('A');
			p++;
		}
	}

	// normalize path name according with the media's rule
	virtual void TJS_INTF_METHOD NormalizePathName(ttstr &name)
	{
		// normalize path name
		// make all characters small
		tjs_char *p = name.Independ();
		while(*p)
		{
			if(*p >= TJS_W('A') && *p <= TJS_W('Z'))
				*p += TJS_W('a') - TJS_W('A');
			p++;
		}
	}

	// check file existence
	virtual bool TJS_INTF_METHOD CheckExistentStorage(const ttstr &name)
	{
		std::string filename;
		if( TVPUtf16ToUtf8( filename, name.c_str() ) )
		{
			struct stat st;
			if( squash_stat( fs, filename.c_str(), &st) == 0)
			{
				if( S_ISREG(st.st_mode) )
				{
					return true;
				}
			}
		}
		return false;
	}

	// open a storage and return a tTJSBinaryStream instance.
	// name does not contain in-archive storage name but
	// is normalized.
	virtual tTJSBinaryStream * TJS_INTF_METHOD Open(const ttstr & name, tjs_uint32 flags) {
		if (flags == TJS_BS_READ) {
			ttstr fname;
			tjs_string wname(name.c_str());
			std::string nname;
			if( TVPUtf16ToUtf8(nname, wname) )
			{
				int vfd = squash_open(fs, nname.c_str());
				if (vfd != -1)
				{
					SquashFsStream *stream = new SquashFsStream(vfd);
					if (stream)
					{
						tTJSBinaryStream *ret = TVPCreateBinaryStreamAdapter(stream);
						stream->Release();
						return ret;
					}
				}
			}
		}
		return NULL;
	}

	// list files at given place
	virtual void TJS_INTF_METHOD GetListAt(const ttstr &name, iTVPStorageLister * lister)
	{
		tjs_string wname(name.c_str());
		std::string nname;
		if( TVPUtf16ToUtf8(nname, wname) )
		{
			SQUASH_DIR* dr;
			if( ( dr = squash_opendir(fs, nname.c_str()) ) != nullptr )
			{
				struct SQUASH_DIRENT* entry;
				while( ( entry = squash_readdir( dr ) ) != nullptr )
				{
					if( entry->d_type == DT_REG ) {
						tjs_char fname[256];
						tjs_int count = TVPUtf8ToWideCharString( entry->d_name, fname );
						fname[count] = TJS_W('\0');
						ttstr file(fname);
						tjs_char *p = file.Independ();
						while(*p) {
							// make all characters small
							if(*p >= TJS_W('A') && *p <= TJS_W('Z'))
								*p += TJS_W('a') - TJS_W('A');
							p++;
						}
						lister->Add(file);
					}
				}
				squash_closedir( dr );
			}
		}
	}

	// basically the same as above,
	// check wether given name is easily accessible from local OS filesystem.
	// if true, returns local OS native name. otherwise returns an empty string.
	virtual void TJS_INTF_METHOD GetLocallyAccessibleName(ttstr &name)
	{
		name = "";
	}

private:
	tjs_uint ref_count;
	ttstr name;
	sqfs *fs;
};

class StoragesSquashFs {

public:
	static ttstr mountSquashFs(ttstr filename) {
		char *data = nullptr;
		ULONG size = 0;
		{
			IStream *in = TVPCreateIStream(filename, TJS_BS_READ);
			if (!in)
			{
				TVPAddLog(TJS_W("krass: could not open ASS file"));
				return false;
			}
			STATSTG stat;
			in->Stat(&stat, STATFLAG_NONAME);
			size = (ULONG)(stat.cbSize.QuadPart);
			data = new char[size];
			HRESULT read_result = in->Read(data, size, &size);
			in->Release();
			if (read_result != S_OK)
			{
				delete[] data;
				return TJS_W("");
			}
		}
		if (data)
		{
			sqfs *sqfs_new = (sqfs *)calloc(sizeof(sqfs), 1);
			sqfs_err err = sqfs_open_image(sqfs_new, (const uint8_t *)data, size);
			if (err == SQFS_OK)
			{
				SquashFsStorage * sfsstorage = new SquashFsStorage(sqfs_new);
				TVPRegisterStorageMedia(sfsstorage);
				ttstr sfsstorage_name;
				sfsstorage->GetName(sfsstorage_name);
				return sfsstorage_name;
			}
		}

		return TJS_W("");
	}
};

NCB_ATTACH_CLASS(StoragesSquashFs, Storages) {
	NCB_METHOD(mountSquashFs);
};

static void PreRegistCallback()
{
	squash_start();
}

NCB_PRE_REGIST_CALLBACK(PreRegistCallback);
