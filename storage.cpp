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

extern "C" ssize_t sqfs_pread(IStream * file, void *buf, size_t count, sqfs_off_t off)
{
	ULARGE_INTEGER new_pos;
	HRESULT seek_result = file->Seek({ off }, STREAM_SEEK_SET, &new_pos);
	if (seek_result != S_OK)
	{
		return -1;
	}
	ULONG size = 0;
	HRESULT read_result = file->Read(buf, count, &size);
	if (read_result != S_OK)
	{
		return -1;
	}
	return size;
}

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

static std::vector<iTVPStorageMedia*> storage_media_vector;

class SquashFsStorage : public iTVPStorageMedia
{

public:
	SquashFsStorage(sqfs *in_fs)
	{
		ref_count = 1;
		fs = in_fs;
		char buf[(sizeof(void *) * 2) + 1];
		snprintf(buf, (sizeof(void *) * 2) + 1, "%p", this);
		// The hash function does not work properly with numbers, so change to letters.
		char *p = buf;
		while(*p)
		{
			if(*p >= '0' && *p <= '9')
				*p = 'g' + (*p - '0');
			p++;
		}
		name = ttstr(TJS_W("squashfs")) + buf;
	}

	virtual ~SquashFsStorage()
	{
		if (fs)
		{
			sqfs_destroy(fs);
			fs->fd->Release();
			fs = NULL;
		}
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
		const tjs_char *ptr = name.c_str();

		// The domain name needs to be "."
		if (!TJS_strncmp(ptr, TJS_W("./"), 2))
		{
			ptr += 1;
			tjs_string wname(ptr);
			std::string nname;
			if( TVPUtf16ToUtf8( nname, name.c_str() ) )
			{
				struct stat st;
				if( squash_stat( fs, nname.c_str(), &st) == 0)
				{
					if( S_ISREG(st.st_mode) )
					{
						return true;
					}
				}
			}
		}
		return false;
	}

	// open a storage and return a tTJSBinaryStream instance.
	// name does not contain in-archive storage name but
	// is normalized.
	virtual tTJSBinaryStream * TJS_INTF_METHOD Open(const ttstr & name, tjs_uint32 flags) {
		if (flags == TJS_BS_READ)
		{
			const tjs_char *ptr = name.c_str();

			// The domain name needs to be "."
			if (!TJS_strncmp(ptr, TJS_W("./"), 2))
			{
				ptr += 1;
				ttstr fname;
				tjs_string wname(ptr);
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
		}
		return NULL;
	}

	// list files at given place
	virtual void TJS_INTF_METHOD GetListAt(const ttstr &name, iTVPStorageLister * lister)
	{
		const tjs_char *ptr = name.c_str();

		// The domain name needs to be "."
		if (!TJS_strncmp(ptr, TJS_W("./"), 2))
		{
			ptr += 1;
			tjs_string wname(ptr);
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
	static ttstr mountSquashFs(ttstr filename)
	{
		IStream *in = nullptr;
		{
			in = TVPCreateIStream(filename, TJS_BS_READ);
			if (!in)
			{
				return TJS_W("");
			}
		}
		if (in)
		{
			sqfs *sqfs_new = (sqfs *)calloc(sizeof(sqfs), 1);
			sqfs_err err = sqfs_open_image(sqfs_new, in, 0);
			if (err == SQFS_OK)
			{
				SquashFsStorage * sfsstorage = new SquashFsStorage(sqfs_new);
				TVPRegisterStorageMedia(sfsstorage);
				storage_media_vector.push_back(sfsstorage);
				ttstr sfsstorage_name;
				sfsstorage->GetName(sfsstorage_name);
				return sfsstorage_name;
			}
			else
			{
				in->Release();
			}
		}

		return TJS_W("");
	}

	static bool unmountSquashFs(ttstr medianame)
	{
		for (auto i = storage_media_vector.begin();
			i != storage_media_vector.end(); i += 1)
		{
			ttstr this_medianame;
			(*i)->GetName(this_medianame);
			if (medianame == this_medianame)
			{
				TVPUnregisterStorageMedia(*i);
				(*i)->Release();
				storage_media_vector.erase(i);
				return true;
			}
		}

		return false;
	}
};

NCB_ATTACH_CLASS(StoragesSquashFs, Storages) {
	NCB_METHOD(mountSquashFs);
	NCB_METHOD(unmountSquashFs);
};

static void PreRegistCallback()
{
	squash_start();
}

static void PostUnregistCallback()
{
	for (auto i = storage_media_vector.begin();
		i != storage_media_vector.end(); i += 1)
	{
		TVPUnregisterStorageMedia(*i);
	}
	squash_halt();
}

NCB_PRE_REGIST_CALLBACK(PreRegistCallback);
NCB_POST_UNREGIST_CALLBACK(PostUnregistCallback);
